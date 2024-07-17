let config = {
    object: 'account__v',
    fields: {
        id: '<insert_account_id_here>',
    },
    target: [
        { id: '<insert_html_report_id>' },
        { external_id__v: '<insert_external_id>' },
    ]
};
ds.viewRecord(config).then(console.log, console.warn);