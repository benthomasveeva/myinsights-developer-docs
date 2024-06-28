let config = {
    target: [
        { id: '<insert_html_report_id>' },
        { external_id__v: '<insert_external_id>' },
    ]
};
ds.viewSection(config).then(console.log, console.warn);