# mangrove-structure-in-placencia

This application visualizes mangrove extent with the mangrove structural data (e.g. trunk thickness, tree height).
Code to work with the published data is also included.

The website is deployed as a static site with documentation on how to reproduce the site with other data.

This website was developed with support from the COPE project.

## Local development

Use `quarto preview --render all` rather than a plain `quarto preview`. This project's
pre-render scripts (in `R/`) re-download the field data and regenerate the derived JSON/GeoJSON
files before every render; with plain `quarto preview`, navigating to a page that hasn't been
rendered yet in the current session triggers one of these re-renders on demand, and the
resulting live-reload can race with (and cancel) the in-flight navigation — clicking a nav link
can land you back on the page you clicked from. `--render all` fully renders every page up front,
so there's nothing left to render on demand and no race.
