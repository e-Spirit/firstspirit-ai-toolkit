# Global content areas: the template owns the output

A **global content area** (GCA) holds content that belongs to the site, not to one page: a header, a footer, a cookie
banner, a contact block. Its content lives on a page of its own, built from a **page template of the global content
area** (prefix `gc_`, see `naming-and-conventions.md`). Facts and syntax are in the `firstspirit-templating-reference`
skill (`templates/system-objects.md`, section "Global content area"); this file is the design view.

## The rule

**The template of the global content area contains the output for everything the global content area covers. The page
template only says where that output goes.**

- In the page template, one call places it `[odfs]`: `$CMS_VALUE(#global.gca("REFERENCE_NAME"))$`, where the argument is the
  reference name of the global content area page `[odfs]`.
- The markup, the conditions and the loops over the content of the global content area belong in the template of the
  global content area, next to the fields they read.
- Do **not** loop through the form data of the global content area from the page template. That puts the rendering of
  one function into every page template that needs it, and defeats the purpose of cutting the site into small chunks
  that each complete one function, are easy to maintain and are changed in one place.

```
<header>
    $CMS_VALUE(#global.gca("gc_header"))$ $-- [odfs] --$
</header>
```

The names are examples: use the reference name the project gives the global content area page. The header's markup,
its navigation fields and its logo are rendered by the template of that global content area.

Good looks like: a page template with a header, a main area and a footer in which each shared part is one line, and
a template of a global content area per shared part that renders it completely.

## Contexts and variables

The call inserts the content of the global content area page at the place of the call, and the context of that page
starts there. Contexts nest `[odfs]`:

- A page and a section of the global content area have their own contexts, named like those of the page they sit on.
  `#global.context("section")` therefore addresses the **innermost** section, usually the one of the global content
  area. `#global.section.id` and `#global.page.id` and their `name` and `uid` do the same.
- Variables set in the page and section templates of a global content area are visible in it and everything inside it.
  To make a variable visible to the elements outside, set it in `#global.context("PAGE")`.
- If a page and a global content area use the same variable identifier, the one of the current element wins. Choose
  identifiers that are unique across the templates that can meet on one page.

## When it is the wrong tool

Whether the content should be a global content area or live in the project settings is decided in
`cutting-an-artifact.md` ("Header and footer: where the content lives").

## Check before finishing

- [ ] The page template contains only the call that places the global content area, not its markup or loops.
- [ ] The template of the global content area renders everything it covers.
- [ ] No variable identifier is shared between the page, the sections and the global content area by accident.
