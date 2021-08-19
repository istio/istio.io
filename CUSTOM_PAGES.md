# Custom Pages
Here are some instructions how you can customize pages of the [Istio website](https://www.istio.io).

## Pages
1. [Homepage](#homepage)
2. [About](#about)
3. [FAQ](#faq)
4. [Blog](#blog)
5. [Get involved](#get-involved)
6. [Documentation](#documentation)
7. [Info banner](#info-banner)

## Homepage
Homepage landing panels are created using the ```{{< content_panel >}}``` shortcode providing the `type` of the panel, `title`, `text`, `button` and `url` (example below).
```
{{< content_panel type="dark" title="service_mesh" text="You can find what you need to make Istio do exactly what you need it to do." button="learn_more" url="/about/service-mesh" >}}
```

### Concepts
Concept blocks reuse the ```{{< content_panel >}}``` shortcode with a small `type="transparent"` parameter difference.

### Solutions
Solutions is a dynamic carousel of the Solution pages listed in `content/en/solutions` rendered using the ```{{< solutions_carousel >}}``` shortcode.

### Case studies
Case studies is a dynamic carousel of the Case study pages listed in `content/en/case-studies` rendered using the ```{{< case_studies_carousel >}}``` shortcode.

## About

### Service mesh
Contains list of concepts rendered using the ```{{< feature_block >}}``` shortcode providing the `header` of the block, `image` path to an image located in the `assets/inline_images` directory and the inner content (example below).
```
{{< feature_block header="Traffic management" image="management.svg" >}}
Istio’s traffic routing rules let you easily control the flow of traffic and API calls between services.
{{< /feature_block >}}
```

The page also contains the Solutions carousel rendered using ```{{< solutions_carousel >}}``` shortcode.

### Solutions
To add a new Solution page, create a new directory in `content/en/about/solutions`, then create an .md file inside the new directory e.g. `content/en/about/solutions/new-solution-name/index.md`.
Make sure the markdown file contains a `title`, `opening_paragraph`, `image`, `type: solutions`, `doc_type: article` and `sidebar_force: sidebar_solution`.

Solutions are generated using a range of ```feature_block``` partials inside the `layouts/solutions/list.html` directory. Solutions lists are all the individual Solution pages.

Each solution contains ```{{ partial "case_study_suggestions" . }}``` which lists 3 case study panels at the bottom of the page.

### Case studies
To add a new Case study page, create a new directory in `content/en/about/case-studies`, then create an .md file inside the new directory e.g. `content/en/about/case-studies/case-study-name/index.md`.

Make sure the markdown file contains a `title`, `quote`, `author` object (with `name` and `image` if you wish to display the author in the Case study sidebar), `companyName`, `companyURL`, `type: case-studies`, `doc_type: article` and `sidebar_force: sidebar_case_study`.

Case studies are generated using a range of ```case_study_panel``` partials inside the `layouts/case-studies/list.html` directory. Case studies lists all the individual Case study pages.

Case studies contain the "Also used by" section rendered using the ```{{< companies >}}``` partial.

### Ecosystem
#### Providers
Providers uses the ```{{< companies >}}``` shortcode with ability to limit the number of visible items using `first` parameter e.g. ```{{< companies first=8 >}}``` will show the first 8 providers.

To create a new provider, amend the `data/companies.yml` and add a new entry in the `providers` list providing a `name` of the provider, `url` to their site and `logo` path to an image which needs to be pasted into the `static/logos` directory.

#### Pro services
To create a new Pro service, amend the `data/companies.yml` and add a new entry in the `pro_services` list providing a `name` of the pro service, `url`, `logo` path to an image which are also pulled from the `static/logos` directory, `description` to be displayed on the ```{{< interactive_panel >}}``` and `details` which is a list of paragraphs to be displayed in the modal window.

Pro services uses the ```{{< interactive_panels >}}``` shortcode with same ability to limit the number of visible items using `first` parameter e.g. ```{{< interactive_panels first=8 >}}``` will show first 8 interactive panels. An interactive panel reacts to a click event which opens up a modal window using the ```interactive_panel``` partial.

```interactive_panel``` accepts the `items` parameter which can be either the `integrations` or defaults to `pro_services`.

#### Integrations
Works in the same fashion as Pro services but is displayed using the ```{{< interactive_panels >}}``` with `items="integrations"` parameter.

### Deployment
To amend the deployment process page, change the contents of the `content/en/deployment/index.md` file.

## FAQ
To add new content to FAQ, create a new markdown file in `content/en/about/faq/` in one of the existing categories. To add new category, create a new directory with an `index.md` markdown file with a category name as the `linktitle` attribute. ```faq_block``` partial uses the `question` and `answer` parameters. `title` attribute of individual markdown files is used as a question and the content is used as an answer.

## Blog
To add a new blog post, go to the appropriate year folder in `content/en/blog` and create a new folder with `index.md` file similar to the existing ones in neighbouring folders (it should have publish date and title). New post will be displayed immediately after.

## Get Involved
To add new content, go to `content/en/get-involved/index.md` file. To add a new section, use `{{% involve_block %}}` with following parameters `title`, `subtitle` and `icon`. Icons in svg format are stored in `src/icons` directory. For description, use inner content (example below).
```
{{% involve_block title="This is title" subtitle="This is subtitle" icon="icon" %}}
Content
{{% /involve_block %}}
```
It is also possible to edit existing content and add more content to each section by typing next number, i.e. `4. New Content`.

## Documentation
To add a new documentation page, go to `content/en/docs`. Select appropriate section or create a new one if needed with `index.md` file, next add a new folder with `index.md` file where content of the page should exist. New page or/and new section will be displayed immediately after, also in the sidebar menu in documentation pages.

## Info banner
To create an event for an info banner, go to `content/en/events/banners` and create new .md file. In addition to the content, you can set parameters such as start date, end date, max impressions or timeout.

# List of new elements
## Components
### Shortcodes
- `{{< content_panel >}}` for displaying triple panels at the top of the homepage and Concepts section of the homepage
- `{{< centered_block >}}` for wrapping components in a centered component with a specific width
- `{{< involve_block >}}` for creating sections in “Get Involved” page
- `{{< multi_block >}}` for creating a component with a title, icon and description useful for describing groups of people. Used on a single Solution page but may be integrated into any markdown
- `{{< solutions_carousel >}}` for displaying the Solutions carousel

### Partials
- `{{ case_studies_carousel }}` for displaying the Case studies carousel
- `{{ case_studies_carousel_panel }}` for displaying a Case studies carousel panel
- `{{ companies }}` for displaying a grid of companies from `data/companies.yml` file
- `{{ faq_block }}` for creating FAQ block (answer and question)
- `{{ feature_block }}` for creating feature components on Service mesh and Solutions
- `{{ sidebar_case_study }}` for displaying a Case study sidebar
- `{{ sidebar_solutions }}` for displaying a Solution sidebar
- `{{ solutions_carousel_panel }}` for displaying the Solutions carousel panel

### Layouts
- `blog/list.html` for displaying list of blog posts which are filtered by publishdate
- `blog/single.html` for displaying single blog post
- `case-studies/list.html` for displaying list of case studies
- `get-involved` for creating “Get Involved” page
- `news/list.html` for displaying list of news which are filtered by section name
- `news/single.html` for displaying single news page
- `solutions/list.html`for displaying list of solutions
- `solutions/single.html` for displaying single solution

### Functions in .ts directory
- `handleFaqBlocks()` for expanding and collapsing FAQ blocks dynamically
- `getByTag()` returns an element whose tagname matches the specified string
- `getByClass()` returns an element whose class name matches the specified string
- `toggleActiveHeader()` for adding a shadow to the header once user scrolls past a specific point on the page

### Functions in static directory
- `categories-filter` window class with methods which enable filtering lists of objects
