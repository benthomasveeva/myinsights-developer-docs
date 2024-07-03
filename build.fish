#!/usr/local/bin/fish
npx elm-pages run CreateDocumentation
elm make ./src/Main.elm --output ./dist/main.js
for d in $simulator_dir
    cp -R ./dist/ $d
end
if test -e ./dist/library.js 
    set -f export_zip ~/Documents/MyInsights_Docs.zip 
end
if test -e ./dist/veeva-crm-library.js
    set -f export_zip ~/Documents/MyInsights_Docs_Veeva_CRM.zip
end
if set -q export_zip
    cd ./dist
    zip -r -FS $export_zip ./
    echo $export_zip
    cd ..
end
