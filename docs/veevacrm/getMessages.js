let tokens = [{ msgName: "OK", msgCategory: "Common" }, { msgName: "Cancel", msgCategory: "Common" }];
ds.getVeevaMessagesWithDefault(tokens).then(console.log, console.warn);
ds.getVeevaMessagesWithDefault(tokens, "en_US").then(console.log, console.warn);
