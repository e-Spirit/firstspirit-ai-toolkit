# Preview image: what the editor sees when choosing a template

The preview image belongs to the **template**, not to the content. It is shown when an editor selects a template from
several options to create content: a section, a page or a table. It is set in the template's settings (Properties tab),
not on the Snippet tab. It is a different use case from the snippet, which describes each individual section by its
content (`snippets.md`). Facts and the ODFS source are in the `firstspirit-templating-reference` skill (its
`templates/preview-image.md`); this file is the design view.

## How much it matters

- **Small project, few templates:** low priority; the template name and description can carry the choice.
- **Many options, and especially several versions of one thing** (three teasers, four hero variants): important. The
  editor chooses by looking, and names alone do not tell the variants apart.

## What to show

It is only a thumbnail, so it has to be understood without details.

- Show **what the template does**: the layout reduced to its blocks (image, text lines, columns, button), not a
  screenshot with real copy that has to be read.
- One look for the whole project: same size, background, colours and level of abstraction on every image, so the choice
  list reads as a set.
- Variants of one template differ in the arrangement of the same few shapes, and the image says the same as the name.
- Where a real screenshot is used instead, crop to the part that distinguishes the template and keep text out.

Observed in the reference projects of the e-commerce connectors (`[observed]` 2026-10-16, template exports of four
reference projects, 40 images): the style is a pictogram, not a screenshot. One project uses 400 x 300 images, a dark
navy rounded rectangle with white shapes only: a rounded bar with dashes for a page with navigation, white boxes with a
mountain and a sun for an image, short white lines for text, a shopping bag or box for a product. Carousel, three-column
teaser grid, product page and homepage are told apart by the arrangement of these few shapes. Another uses 512 x 512
line icons in blue on a light gradient with the same vocabulary (image, text lines, button). A third style is a real
frontend screenshot, where text cannot be read at thumbnail size. Prefer the pictogram style; it is a choice of those
projects, not a documented requirement. The files are `PreviewImage.png` in the template's export folder.

## In the build

- Every template an editor chooses among others gets one, in proportion to the number of options (above).
- Whether it can be set over REST is open in the reference; until then hand over the image together with the template name and the setting to make.
- In a review, a project with many or versioned templates and no preview images is a finding; a small project without
  them is a note.
