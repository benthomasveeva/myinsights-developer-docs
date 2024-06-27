# myinsights-developer-docs

Hand-built with Elm. Using `elm-pages` and `elm-codegen`. 

## Adding documentation

All documentation and code examples are added to the `./docs` directory. 

First, `docs.json` contains all of the documentation entries that will be displayed. Inside of the giant object, the key is what will be displayed on the left sidebar and the value contains the documentation. 

Second, each entry in docs.json can have a JS file whose name matches the key from `docs.js` (e.g. `./docs/queryRecord.js`). 

Third, each entry can have additional named examples by placing JS files in a directory whose name matches the key from `docs.js` (e.g. `./docs/queryRecord/minimal.js`). 

## Build

```bash
npx elm-pages run CreateDocumentation
elm make ./src/Main.elm --output ./dist/main.js
```
