import React from 'react';
import {Avatar, Breadcrumb, Layout, List} from "antd";
import {
    FileExcelOutlined,
    FileOutlined,
    FilePdfOutlined,
    FilePptOutlined,
    FileTextOutlined,
    FileWordOutlined,
    FileZipFilled,
    FolderOutlined,
    HomeOutlined
} from "@ant-design/icons";
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
        this.list("/")
    }

    onClickItem(item) {
        if (item.type === "DIR") {
            this.list(item.path)
        }
    }

    list(path) {
        this.dispatch(FileActions.showLoading({}))
        FileApi.list(path).then(resp => {
            console.log(resp)
            if (resp.success) {
                this.dispatch(FileActions.onLoaded(resp.data))
            } else if (resp.message === "RetryLaterAgain") {
                setTimeout(() => this.list(path), 200)
            } else {
                this.dispatch(FileActions.onLoaded({}))
            }
        })
    }

    getIcon(item) {
        if (item.type === "DIR") {
            return <FolderOutlined/>
        }
        if (item.ext === ".PDF") {
            return <FilePdfOutlined/>
        }
        if (item.ext === ".XLS" || item.ext === ".XLSX") {
            return <FileExcelOutlined/>
        }
        if (item.ext === ".PPT" || item.ext === ".PPTX") {
            return <FilePptOutlined/>
        }
        if (item.ext === ".DOC" || item.ext === ".DOCX") {
            return <FileWordOutlined/>
        }
        if (item.ext === ".TXT") {
            return <FileTextOutlined/>
        }
        if (item.ext === ".ZIP") {
            return <FileZipFilled/>
        }
        return <FileOutlined/>
    }

    fileThumb(item) {
        if (item["thumbnail"].length > 0) {
            return <Avatar style={{marginRight: 10}} shape={"square"}
                           src={"http://localhost:8080" + item["thumbnail"]}/>
        }
        return <Avatar style={{marginRight: 10}} shape={"square"}
                       icon={this.getIcon(item)}/>
    }

    render() {
        const {data, initLoading} = this.props;
        const nav = data.navigate || []
        const list = data.files || []

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
                    <Breadcrumb.Item key={"/"} style={{cursor: "pointer"}} onClick={e => this.list("/")}>
                        <HomeOutlined/>
                    </Breadcrumb.Item>
                    {nav.map((item, index) => {
                        return index === nav.length - 1 ?
                            <Breadcrumb.Item key={item.path}>
                                {item.name}
                            </Breadcrumb.Item>
                            :
                            <Breadcrumb.Item key={item.path} style={{cursor: "pointer"}}
                                             onClick={e => this.list(item.path)}>
                                {item.name}
                            </Breadcrumb.Item>
                    })}
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
                    dataSource={list}
                    renderItem={(item) => (
                        <List.Item key={item.path} style={{cursor: "pointer"}} onClick={e => this.onClickItem(item)}>
                            <div style={{display: "flex"}}>
                                {this.fileThumb(item)}
                                <div>
                                    <div>{item.name}</div>
                                    <div style={{color: "gray"}}>{item.modTime} {item.size}</div>
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
