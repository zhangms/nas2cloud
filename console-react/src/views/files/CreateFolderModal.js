import React from 'react';
import {Form, Input, Modal} from "antd";

const FolderCreateForm = ({open, onCreate, onCancel}) => {
    const [form] = Form.useForm();
    return (
        <Modal
            open={open}
            title="Create a new Folder"
            onCancel={onCancel}
            onOk={() => {
                form.validateFields()
                    .then((values) => {
                        form.resetFields();
                        onCreate(values);
                    })
                    .catch((info) => {
                        console.log('Validate Failed:', info);
                    });
            }}
        >
            <Form
                form={form}
                layout="vertical"
                name="form_in_modal"
                initialValues={{
                    modifier: 'public',
                }}
            >
                <Form.Item
                    name="folderName"
                    rules={[
                        {
                            required: true,
                            message: 'Please input the folder name',
                        },
                    ]}
                >
                    <Input placeholder={"input folder name"}/>
                </Form.Item>
            </Form>
        </Modal>
    );
};

export default FolderCreateForm
