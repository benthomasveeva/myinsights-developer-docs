let config = { 
    object: "Account", 
    fields: ["Id", "Name"],
    where: "IsPersonAccount = true",
    sort: ["Name ASC"],
    limit: 10
}; 
ds.runQuery(config).then(console.log,console.warn);