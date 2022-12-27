import React from 'react';
import {Avatar, Breadcrumb, Layout, List} from "antd";
import {HomeOutlined, UserOutlined} from "@ant-design/icons";
import {Content, Header} from "antd/es/layout/layout";
import {connect} from "react-redux";
import FileApi from "../../requests/api_file";
import {FileActions} from "../../models/file";

class FileManager extends React.Component {

    constructor(props) {
        super(props);
        this.dispatch = props.dispatch
    }

    componentDidMount() {
        FileApi.list("/").then(resp => {
            this.dispatch(FileActions.onLoaded(resp.data))
        })
    }

    render() {
        const {data, initLoading} = this.props;
        return <Layout>
            <Header style={{
                background: "#f5f5f5",
                position: 'sticky',
                top: 0,
                zIndex: 1,
                width: '100%',
            }}>
                <Breadcrumb style={{
                    margin: '20px -30px',
                }}>
                    <Breadcrumb.Item href="">
                        <HomeOutlined/>
                    </Breadcrumb.Item>
                    <Breadcrumb.Item href="">
                        <UserOutlined/>
                        <span>Application List</span>
                    </Breadcrumb.Item>
                    <Breadcrumb.Item>Application</Breadcrumb.Item>
                </Breadcrumb>
            </Header>
            <Content style={{
                background: "white",
                paddingTop: 10
            }}>
                <List
                    loading={initLoading}
                    itemLayout="horizontal"
                    size={"small"}
                    dataSource={data}
                    renderItem={(item) => (
                        <List.Item>
                            <div style={{display: "flex"}}>
                                <Avatar style={{marginRight: 10}} shape={"square"}
                                        src="https://randomuser.me/api/portraits/women/16.jpg"/>
                                <div>
                                    <div>{item.Name}</div>
                                    <div style={{color: "gray"}}>{item.ModTime} {item.Size}</div>
                                </div>
                            </div>
                        </List.Item>
                    )}
                />
            </Content>
        </Layout>
    }
}

export default FileManager = connect(function (state) {
    return {...state.File}
})(FileManager)
