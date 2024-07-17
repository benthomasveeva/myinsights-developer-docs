let config = { 
    object: "Table_Name__c", 
    fields: ["Id", "Name"],
    where: "SomeField__c = true",
    sort: ["Name ASC"],
    limit: 10
}; 
ds.queryVDSRecord(config).then(console.log,console.warn);
