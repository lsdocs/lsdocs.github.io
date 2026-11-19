# Helpers shared by the repositories of the lsdocs organization: checks on
# how a repository depends on the others, and linking local checkouts.
#
# `scripts/org.nuon` lists every repository of the organization and the
# crates it holds; the checks read it. It is copied from the monorepo's
# `tools/split/repos.nuon` by `nur split`; keep it current when a
# repository or crate is added.

# The base URL of the organization's repositories.
export const ORG_URL = "https://github.com/lsdocs"

# The dependency tables of a parsed Cargo manifest, as `{table, name, spec}`
# rows: `[workspace.dependencies]`, `[dependencies]`, `[dev-dependencies]`,
# `[build-dependencies]` and their `[target.*]` forms.
def dependency-rows [manifest: record]: nothing -> list<record> {
    let kinds = [dependencies dev-dependencies build-dependencies]
    mut tables = []
    let ws = $manifest | get -o workspace.dependencies
    if $ws != null { $tables = ($tables | append {table: "workspace.dependencies", deps: $ws}) }
    for kind in $kinds {
        let t = $manifest | get -o $kind
        if $t != null { $tables = ($tables | append {table: $kind, deps: $t}) }
    }
    let targets = $manifest | get -o target | default {}
    for target in ($targets | columns) {
        for kind in $kinds {
            let t = $targets | get $target | get -o $kind
            if $t != null { $tables = ($tables | append {table: $"target.($target).($kind)", deps: $t}) }
        }
    }
    $tables | each {|t|
        $t.deps | columns | each {|name| {table: $t.table, name: $name, spec: ($t.deps | get $name)} }
    } | flatten
}

# Whether `path` (a path dependency, relative to the manifest's directory
# `dir`, itself relative to the repository root) stays inside the
# repository.
def inside-repo [path: string, dir: string]: nothing -> bool {
    let p = $path | str replace --all '\' '/'
    if ($p | str starts-with "/") or ($p =~ '^[A-Za-z]:') { return false }
    mut depth = 0
    for part in ($"($dir)/($p)" | split row "/" | where {|s| $s != "" and $s != "." }) {
        $depth = if $part == ".." { $depth - 1 } else { $depth + 1 }
        if $depth < 0 { return false }
    }
    true
}

# Checks that every `lsdocs-*` dependency of `manifest` (a parsed
# `Cargo.toml` in the directory `dir`, relative to the repository root) is
# a path dependency inside the repository, inherited from the workspace,
# or a git dependency on the organization repository that holds that crate
# (`org`: repository name -> list of crate names), and that the manifest
# has no `[patch]` table (local patches belong in the untracked
# .cargo/config.toml). Returns error messages.
export def check-git-deps [manifest: record, org: record, --dir: string = "."]: nothing -> list<string> {
    let patch = if ($manifest | get -o patch) != null {
        ["a committed [patch] table: use `nur link` (untracked .cargo/config.toml) instead"]
    } else { [] }
    $patch | append (dependency-rows $manifest | where {|r| $r.name | str starts-with "lsdocs" } | each {|r|
        let spec = if ($r.spec | describe | str starts-with "record") { $r.spec } else { {version: $r.spec} }
        let crate = $spec | get -o package | default $r.name
        let path = $spec | get -o path
        if $path != null {
            if (inside-repo $path $dir) { null } else { $"`($crate)` in [($r.table)] is a path outside this repository: ($path)" }
        } else if ($spec | get -o workspace) == true {
            null
        } else if ($spec | get -o git) == null {
            $"`($crate)` in [($r.table)] is neither a path nor a git dependency"
        } else {
            let url = $spec.git | str trim --right --char "/" | str replace -r '\.git$' ""
            let repo = $url | str replace $"($ORG_URL)/" ""
            if not ($url | str starts-with $"($ORG_URL)/") {
                $"`($crate)` in [($r.table)] is not from ($ORG_URL): ($spec.git)"
            } else if not ($repo in ($org | columns)) {
                $"`($crate)` in [($r.table)] names `($repo)`, which is not a repository of the organization"
            } else if not ($crate in ($org | get $repo)) {
                $"`($crate)` in [($r.table)] is not a crate of `($repo)`"
            } else {
                null
            }
        }
    } | compact)
}

# The `lsdocs-*` crates `cargo tree --duplicates` reports (its text):
# a crate there is built twice, from two sources or at two versions.
export def dupes [tree: string]: nothing -> list<string> {
    $tree | lines
        | where {|l| $l =~ '^lsdocs[a-z0-9_-]* v' }
        | each {|l| $l | split row " " | first }
        | uniq
}

# The duplicates in `cargo tree --duplicates`'s result (`complete`'s
# record); a failed run is an error, never "no duplicates".
export def tree-dupes [result: record]: nothing -> list<string> {
    if $result.exit_code != 0 {
        error make --unspanned {msg: $"cargo tree failed: ($result.stderr)"}
    }
    dupes $result.stdout
}

# The environment that makes Cargo fetch the organization's repositories
# from local clones in `dir` (their committed `main`), instead of from
# GitHub: for working before they are pushed, or offline. Empty unless
# `LSDOCS_ORG_DIR` is set.
export def org-env []: nothing -> record {
    let dir = $env | get -o LSDOCS_ORG_DIR
    if $dir == null or $dir == "" { return {} }
    let base = $dir | path expand | str replace --all '\' '/' | str trim --right --char "/"
    {
        CARGO_NET_GIT_FETCH_WITH_CLI: "true"
        GIT_CONFIG_COUNT: "1"
        GIT_CONFIG_KEY_0: $"url.file:///($base)/.insteadOf"
        GIT_CONFIG_VALUE_0: $"($ORG_URL)/"
    }
}

# The `[patch]` entries pointing the organization repository `repo`'s
# crates at a local checkout `dir`: `{name: {path}}` for each crate
# manifest found under it.
export def patch-entries [dir: string, crates: list<string>]: nothing -> record {
    glob $"($dir | path expand | str replace --all '\' '/')/{crates,bindings,tools}/*/Cargo.toml"
        | each {|m| {name: (open $m | get package.name), path: ($m | path dirname | str replace --all '\' '/')} }
        | where {|c| $c.name in $crates }
        | reduce --fold {} {|c, acc| $acc | insert $c.name {path: $c.path} }
}
