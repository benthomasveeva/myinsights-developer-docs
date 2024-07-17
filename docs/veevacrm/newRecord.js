let config = {
    object: 'Account',
    fields: {
        Name: 'Testy McTesterson',
    },
};
ds.newRecord(config).then(console.log, console.warn);