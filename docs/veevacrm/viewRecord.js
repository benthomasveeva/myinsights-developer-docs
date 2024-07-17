let config = {
    object: 'Account',
    fields: {
        ID: '<insert_account_id_here>',
    },
    target: [
        { ID: '<insert_html_report_id>' },
        { External_Id_vod__c: '<insert_external_id>' },
    ],
};
ds.viewRecord(config).then(console.log, console.warn);