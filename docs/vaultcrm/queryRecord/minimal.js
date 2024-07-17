let config = {
    object: "user__sys",
    fields: ["id", "name__v"]
};
ds.queryRecord(config).then(console.log, console.warn);