:nav_order: 4

.. _restructuredtext:

reStructuredText
================

reStructuredText pages (``.rst``) are parsed by ``parser-rst``, whose
parser is a port of docutils', checked against docutils' own output. The
markup, directives and roles are docutils' standard ones; this page is
written in it.

Titles and metadata
-------------------

Every title starts a section, nested by the order in which underline styles
first appear. As in Sphinx, the first title is not taken out of the page:
it stays the first section, and names the page.

A field list at the very top of a page is its front matter: ``:author:``,
``:date:``, ``:nav_order:`` and any other field. ``:title:`` names the page.

Links
-----

References work as in docutils, within a page: ```Links`_`` points to this
section, and labels name any place:

.. code:: rst

   .. _install-step:

   Install the program first.

   See install-step_ or `the step <install-step_>`_.

Two roles from Sphinx link across the site:

``:ref:`label```
   Links to the label ``label`` on any page, and shows the title of the
   section it names: :ref:`restructuredtext` is this page. Give the text
   yourself with ``:ref:`text <label>```.

``:doc:`path```
   Links to another reStructuredText page, given without its extension,
   relative to this page (or to the source directory with a leading
   ``/``).

Labels become ids as docutils makes them: ``My Label`` is ``my-label``.

Directives
----------

The standard directives work, among them ``note`` and the other
admonitions, ``code``, ``math``, ``figure``, ``image``, the table
directives, ``contents``, ``sectnum`` and ``include``. ``include``, and the
``:file:`` options of ``raw`` and ``csv-table``, read files relative to the
page.

.. note::

   A directive lsdocs does not know is kept as a ``custom`` node of the
   same name, with its argument, options and content, for a plugin to
   handle. The HTML renderer writes it as an empty ``div`` with the
   directive's name as its class.

Problems
--------

docutils' warnings (an unknown target name, a malformed table) are
reported as warnings with their location; its severe errors fail the
build.
