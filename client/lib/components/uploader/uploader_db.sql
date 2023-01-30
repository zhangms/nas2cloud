CREATE TABLE t_upload_entry (
    id INTEGER PRIMARY KEY,
    channel TEXT,
    src TEXT,
    dest TEXT,
    size INTEGER,
    lastModified INTEGER,
    createTime INTEGER,
    beginUploadTime INTEGER,
    endUploadTime INTEGER,
    uploadTaskId TEXT,
    status TEXT,
    message TEXT
);

CREATE UNIQUE INDEX t_upload_entry_index1 on t_upload_entry (src);

CREATE UNIQUE INDEX t_upload_entry_index2 on t_upload_entry (src, dest);

CREATE INDEX t_upload_entry_index3 on t_upload_entry (channel);

CREATE INDEX t_upload_entry_index3 on t_upload_entry (uploadTaskId);
