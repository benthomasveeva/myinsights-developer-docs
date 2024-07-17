let tokens = [{ name: "OK", group: "Common" }, { name: "Cancel", group: "Common" }];
ds.getMessages(tokens).then(console.log, console.warn);
