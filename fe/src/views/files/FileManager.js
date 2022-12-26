import React from 'react';
import {Avatar, Breadcrumb, Button, Layout, List} from "antd";
import {HomeOutlined, UserOutlined} from "@ant-design/icons";
import {Content, Header} from "antd/es/layout/layout";

class FileManager extends React.Component {

    render() {

        const data = [
            {
                title: 'Ant Design Title 1',
            },
            {
                title: 'Ant Design Title 2',
            },
            {
                title: 'Ant Design Title 3',
            },
            {
                title: 'Ant Design Title 4',
            },
        ];

        const loadMore = function () {
            return <div
                style={{
                    textAlign: 'center',
                    marginTop: 12,
                    height: 32,
                    lineHeight: '32px',
                }}
            >
                <Button>loading more</Button>
            </div>;
        }

        return <Layout>
            <Header style={{
                background: "#f5f5f5",
                position: 'sticky',
                top: 0,
                zIndex: 1,
                width: '100%',
            }}>
                <Breadcrumb style={{
                    margin: '18px 0',
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
                background: "white"
            }}>
                <List
                    itemLayout="horizontal"
                    size={"small"}
                    dataSource={data}
                    loadMore={loadMore()}
                    renderItem={(item) => (
                        <List.Item>
                            <div style={{display: "flex"}}>
                                <Avatar style={{marginRight: 10}} shape={"square"}
                                        src="https://randomuser.me/api/portraits/women/16.jpg"/>
                                <div>
                                    <div>HELLO</div>
                                    <div style={{color: "gray"}}>2020-12-12 38kb</div>
                                </div>
                            </div>
                        </List.Item>
                    )}
                />
            </Content>
        </Layout>
    }
}

export default FileManager
