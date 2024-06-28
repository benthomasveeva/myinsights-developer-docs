ds.getDataEngineTables().then((resp) => {
    if(resp.data && Object.keys(resp.data)[0]){
        let tableName = Object.keys(resp.data)[0];
        console.log("Getting metadata for " + tableName);
        return ds.getDataEngineTableMetadata(tableName);
    } else {
        return "No tables"
    }
}).then(console.log, console.warn);