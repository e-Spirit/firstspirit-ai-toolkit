# Automatic image cropping (FirstSpirit Image Assistant)

Automatic and AI-assisted cropping of images in ContentCreator. **[odfs]** — *Template
development › ContentCreator › Automatic cropping*, FirstSpirit 2026.5. Not re-tested live
**[verify]**. Manual cropping in the preview and the `editorId(resolution:)` call:
`editing-in-the-preview.md`. The same module also drives AI alt-text generation, covered with
the AI suite: `firstspirit-ai-suite`.

## What it does

The module "FirstSpirit Image Assistant" analyses uploaded images with the image-recognition
service **Amazon Rekognition**, stores the result as **tags with coordinates** in image
metadata, and uses it for three things:

| Function | Behaviour |
| --- | --- |
| **Automatic cropping** ("AutoCropping") | At upload, every resolution is cropped around the recognised subject. Default order: **face**, **several faces** (frame around all), **object**, **several objects**. The editor can check and adjust each crop. |
| **Focus areas** | No automatic crop, but recognised subjects are framed; the editor picks one with a click. |
| **Centre cropping** | The fallback: crop from the centre, focus area named "Image center", every resolution cut to the largest possible size at its aspect ratio. Also used when nothing is recognised (landscapes) or a tag cannot be located. |

With the "AWS Connector" service running (default), images are also created with the right aspect
ratio on upload, so resolutions with a fixed ratio no longer compress the image. [odfs]
Tags are searchable in FirstSpirit's search. [odfs]

## What switches what

The prerequisite is that **"SmartCropping" is on for the resolution** (project properties >
resolutions; on by default for all). A resolution with it off gets no focus area and no crop; the
editor crops it by hand under "Manual croppings". On top of that: [odfs]

| Mode | Project component "FS Image Assistant – Configuration": *Automatic Cropping enabled* | Metadata fields defined |
| --- | --- | --- |
| Automatic cropping | on | yes |
| Focus areas, manual choice | off | yes |
| Centre cropping | on | **no** |
| Module functions off (manual cropping only, no re-analyse icon) | off | no |

"Metadata defined" means at least one `fsai_…` field exists in the metadata template. **Images are
analysed only for content types that define those fields**, and only the categories whose fields
exist are requested. The server-wide default is the connector's "Automatic cropping enabled by
default" checkbox (off by default); a project setting overrides it.

## Setup

1. **Module** — only for installations that are not on the managed cloud: install the
   `imagerecognition-module` FSM. [odfs]
2. **Connector service** "FS Image Assistant – AWS Connector": *Access key* and *Secret key* of an
   IAM user, optional *S3 bucket name* (needed for images **over 5 MB**; stored there only
   temporarily; without it only images under 5 MB are analysed), optional *Preferred folder name*
   (letters, digits, `.`, `-`, `_`; starts and ends with a letter or digit; at least two
   characters), *AWS Region* (detected on an AWS host, otherwise Ireland); "Test configuration"
   checks it. Keys are credentials: never put them in a template or a skill. [odfs]
3. **Web component** "FS Image Assistant – ContentCreator Resources" added to the **global**
   ContentCreator web application, then update the web server. For a **local project**
   ContentCreator instance add the component to that instance (project properties > web
   components > ContentCreator) and deploy; the instance is briefly unavailable. A global
   instance is recommended for resource and maintenance reasons. [odfs]
4. **Metadata template** (below).
5. **ContentCreator settings:** the metadata form is shown in ContentCreator only if configured
   in the project's ContentCreator settings, "Metadata" area. [odfs]

## Metadata fields (`CMS_INPUT_TEXTAREA`, identifiers exact)

| Identifier | Holds |
| --- | --- |
| `fsai_facesPayload` | faces (Rekognition `DetectFaces`) |
| `fsai_objectsPayload` | objects (Rekognition `DetectLabels`) |
| `fsai_textPayload` | recognised text |
| `fsai_unsafeContentPayload` | potentially inappropriate content |
| `fsai_celebritiesPayload` | recognised celebrities |
| `fsai_tags` | the tags, with generic terms and synonyms; usable for tagging |
| `fsai_focusPreference` | **input**, not result: terms steering the focus area |

The payloads are stored as JSON, in English. Each analysed category is **one request
to Amazon**: define only the fields you need; the text, unsafe-content and celebrity fields are
for specialised cases. [odfs]

```xml
<CMS_INPUT_TEXTAREA name="fsai_tags">
  <LANGINFOS><LANGINFO lang="*" label="FS AI - Tags"/></LANGINFOS>
</CMS_INPUT_TEXTAREA>
```

## Steering the focus area

A face is not always the subject. Put `fsai_focusPreference` into the metadata form of **media
folders** and enter terms there (as they appear in `fsai_tags` of analysed images): `Car`, or
several comma-separated, `Tablet Computer, Mobile Phone`. Images uploaded to that folder prefer
those objects, **in the order given**; only objects for which a focus area was located count. The
setting is inherited by subfolders (inheritance can be switched off); empty means the default
order. [odfs]

## Limits to tell the customer

- **Formats:** JPEG, PNG and WebP. Other formats get no metadata, so no automatic crop and no
  focus areas. [odfs]
- **Quality:** the service recommends minimum image and subject sizes; blurry images lower the
  result. Some tags are returned without coordinates and then give no focus area. [odfs]
- **Data and cost:** images are sent to the image-recognition service when they are uploaded or analysed on demand; each analysis is a request to that service. Check the current terms with your FirstSpirit contact. [odfs]
