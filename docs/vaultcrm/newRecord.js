let config = {
    object: 'medical_inquiry__v',
    fields: {
        account__v: '<insert_account_id_here>',
    },
};
ds.newRecord(config).then(console.log, console.warn);