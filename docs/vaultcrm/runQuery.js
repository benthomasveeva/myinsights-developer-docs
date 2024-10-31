let config = { 
    object: "account__v", 
    fields: ["id", "name__v"],
    where: "name__v != 'Matthew'",
    sort: ["name__v ASC"],
    limit: 10
}; 
ds.runQuery(config).then(console.log,console.warn);