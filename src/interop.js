// This is called BEFORE your Elm app starts up
// 
// The value returned here will be passed as flags 
// into your `Shared.init` function.
export const flags = ({ env }) => {

}

const originalLog = console.log; 
const originalWarn = console.warn;
const originalError = console.error;

// This is called AFTER your Elm app starts up
//
// Here you can work with `app.ports` to send messages
// to your Elm application, or subscribe to incoming
// messages from Elm
export const onReady = ({ app, env }) => {
    if (app.ports && app.ports.elmToJs && app.ports.console) {
        console.log = function(...args) { 
            originalLog(...args);
            app.ports.console.send({level: "LOG", args: [...args]});
        }; 
        console.warn = function(...args) {
            originalWarn(...args);
            app.ports.console.send({level:"WARN", args: [...args]});
        }
        console.error = function(...args) {
            originalError(...args);
            app.ports.console.send({level:"ERROR", args: [...args]});
        }
        app.ports.elmToJs.subscribe(({ tag, data }) => {
          // Print out the message sent from Elm
          originalLog(tag, data);
          switch (tag) {
            case "RUN_JS":
                try {
                    eval(data.code);
                } catch (error) {
                    app.ports.console.send({ level: "ERROR", args: [error.message, "\n", error.stack]}); 
                    originalError("Uncaught", error);
                }
                break;
          
            default:
                break;
          }
        })
      }
}