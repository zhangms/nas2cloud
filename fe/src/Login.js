import React from 'react';
import {Alert, Button, Form, Input} from 'antd';
import {LockOutlined, UserOutlined} from "@ant-design/icons";
import API from "./api";

class Login extends React.Component {

    constructor(props) {
        super(props);
        this.state = {
            "alertDisplay": "none",
            "alertMessage": ""
        }
    }

    async onFinish(values) {
        this.setState({
            "alertDisplay": "none",
            "alertMessage": ""
        })
        const resp = await API.login(values)
        if (!resp.success) {
            this.setState({
                "alertDisplay": "",
                "alertMessage": resp.message
            })
            return
        }
        console.log("login success");

    }

    render() {
        return (
            <Form
                style={{marginTop: "12%"}}
                wrapperCol={{span: 8, offset: 8}}
                name="normal_login"
                className="login-form"
                initialValues={{
                    remember: true,
                }}
                onFinish={e => this.onFinish(e)}
            >
                <Form.Item
                    name="username"
                    rules={[
                        {
                            required: true,
                            message: 'Please input your Username!',
                        },
                    ]}
                >
                    <Input prefix={<UserOutlined className="site-form-item-icon"/>} placeholder="Username"/>
                </Form.Item>
                <Form.Item
                    name="password"
                    rules={[
                        {
                            required: true,
                            message: 'Please input your Password!',
                        },
                    ]}
                >
                    <Input
                        prefix={<LockOutlined className="site-form-item-icon"/>}
                        type="password"
                        placeholder="Password"
                    />
                </Form.Item>
                <Form.Item>
                    <Alert
                        style={{display: this.state.alertDisplay}}
                        message="Error Text"
                        description={this.state.alertMessage}
                        type="error"
                    />
                </Form.Item>
                <Form.Item>
                    <Button type="primary" htmlType="submit" className="login-form-button">
                        Log in
                    </Button>
                </Form.Item>
            </Form>
        );
    }
}

export default Login;
