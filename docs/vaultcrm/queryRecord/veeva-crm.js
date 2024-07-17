let config = {
    object: 'Account',
    fields: ['Name', 'id'],
    where: "Name != 'Matthew'",
    sort: ['Name ASC'],
    limit: 10,
};
ds.queryRecord(config).then(console.log, console.warn);
