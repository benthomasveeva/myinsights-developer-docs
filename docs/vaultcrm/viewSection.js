let targets = [
    { ID: '<insert_html_report_id>' },
    { external_id__v: '<insert_external_id>' },
];
ds.viewSection(targets).then(console.log, console.warn);