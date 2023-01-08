import React from 'react';
import Dragger from "antd/es/upload/Dragger";
import {InboxOutlined} from "@ant-design/icons";
import {Modal} from "antd";

class UploadFileModal extends React.Component {

    render() {
        const {open, onClose, onChange, uploadUrl, path} = this.props
        return <Modal
            open={open}
            onCancel={onClose}
            onOk={onClose}
        >
            <Dragger
                name={"file"}
                multiple={true}
                action={uploadUrl}
                onChange={onChange}
                crossOrigin={"use-credentials"}
                withCredentials={true}
                data={file => {
                    return {
                        lastModified: file.lastModified,
                        lastModifiedDate: file.lastModifiedDate,
                    }
                }}
            >
                <p className="ant-upload-drag-icon">
                    <InboxOutlined/>
                </p>
                <p className="ant-upload-text">Click or drag file to this area to upload file to :</p>
                <p className="ant-upload-hint">
                    {path}
                </p>
            </Dragger>
        </Modal>
    }

}

export default UploadFileModal
