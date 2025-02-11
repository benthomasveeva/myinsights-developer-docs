#!/usr/local/bin/fish

# common
nvm use 18
echo "Building common file(s)"
rollup -c

# Veeva CRM
echo ""
echo "Building for Veeva CRM"
npx elm-pages run CreateVeevaCrmDocumentation
elm make ./src/Main.elm --output ./dist/main.js
if test -e ./dist/library.js
    rm ./dist/library.js
end
cp ./src/veeva-crm-library.js ./dist/library.js
for d in $veeva_simulator_dir
    echo "copying to simulator: $d"
    cp -R ./dist/ $d
end
set -f export_zip ~/Documents/MyInsights_Docs_Veeva_CRM.zip
cd ./dist
echo "writing to zip: $export_zip"
zip -r -FS $export_zip ./
cd ..

# Veeva CRM
echo ""
echo "Building for Vault CRM"
npx elm-pages run CreateVaultCrmDocumentation
elm make ./src/Main.elm --output ./dist/main.js
if test -e ./dist/library.js
    rm ./dist/library.js
end
cp ./src/vault-crm-library.js ./dist/library.js
for d in $vault_simulator_dir
    echo "copying to simulator: $d"
    cp -R ./dist/ $d
end
set -f export_zip ~/Documents/X-Pages_Docs.zip
cd ./dist
echo "writing to zip: $export_zip"
zip -r -FS $export_zip ./
cd ..

# Experimental Vault CRM
# We know we're running after the normal Vault, so just copy the files
cp ./dist/codemirror-element.js ./dist_alt/codemirror-element.js
cp ./dist/main.js ./dist_alt/main.js
rollup --config ./rollup-newlibrary.config.mjs
set -f export_zip ~/Documents/X-Pages_Experimental.zip
echo "writing to zip: $export_zip"
cd ./dist_alt
zip -r -FS $export_zip ./
cd ..
