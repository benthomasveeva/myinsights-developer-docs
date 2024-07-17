let targets = [
    { ID: '<insert_html_report_id>' },
    { External_Id_vod__c: '<insert_external_id>' },
];
ds.viewSection(targets).then(console.log, console.warn);