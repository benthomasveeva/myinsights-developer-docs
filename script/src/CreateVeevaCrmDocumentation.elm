module CreateVeevaCrmDocumentation exposing (run)

import CreateDocumentation
import Pages.Script exposing (Script)


run : Script
run =
    CreateDocumentation.generateFromDirectory "veevacrm"
