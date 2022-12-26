import React from 'react';
import {LockOutlined, UserOutlined} from "@ant-design/icons";
import {Alert, Button, Form, Input} from "antd";
import {connect} from "react-redux";
import API from "../../requests/api";
import {LoginActions} from "../../models/login";
import {AppActions} from "../../models/app";

class Login extends React.Component {

    async onFinish(dispatch, values) {
        dispatch(LoginActions.closeError())
        const resp = await API.login(values)
        if (resp.success) {
            API.saveLoginState(resp.data)
        } else {
            API.saveLoginState(resp.data)
            dispatch(LoginActions.showError(resp))
        }
        dispatch(AppActions.updateLoginState())
    }

    render() {
        console.log(this.props)
        const {errorDisplay, errorMessage, dispatch} = this.props
        return (
            <Form
                style={{marginTop: "12%"}}
                wrapperCol={{span: 8, offset: 8}}
                name="normal_login"
                className="login-form"
                initialValues={{
                    remember: true,
                }}
                onFinish={e => this.onFinish(dispatch, e)}
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
                        style={{display: errorDisplay}}
                        message="Error Text"
                        description={errorMessage}
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

export default Login = connect(function (state) {
    return {...state.Login}
})(Login)
