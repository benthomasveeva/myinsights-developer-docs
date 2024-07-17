let config = {
    object: "User",
    fields: ["Id", "Name"]
};
ds.queryRecord(config).then(console.log, console.warn);