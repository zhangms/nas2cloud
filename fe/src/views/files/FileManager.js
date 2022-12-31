import React from 'react';
import {Avatar, Breadcrumb, Button, Layout, List, Skeleton} from "antd";
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
        this.loadInit("/")
    }

    onClickFileItem(item) {
        if (item.type === "DIR") {
            this.loadInit(item.path)
        }
    }

    loadInit(path) {
        this.dispatch(FileActions.initLoading({}))
        FileApi.walk({
            "path": path,
            "pageNo": 0,
            "orderBy": "fileName_asc",
        }).then(resp => {
            console.log(resp)
            if (resp.success) {
                this.dispatch(FileActions.onLoaded(resp.data))
            } else if (resp.message === "RetryLaterAgain") {
                setTimeout(() => this.loadInit(path), 200)
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

    loadMoreBtn(initLoading, moreLoading, data) {
        if (initLoading || moreLoading || data.total == null || data["total"] <= data["currentIndex"]) {
            return null;
        }
        return <div
            style={{
                textAlign: 'center',
                marginTop: 12,
                height: 32,
                lineHeight: '32px',
            }}
        >
            <Button onClick={e => this.loadMore(data)}>loading more</Button>
        </div>
    }

    loadMore(currentData) {

        this.dispatch(FileActions.moreLoading({}))
        FileApi.walk({
            "path": currentData["currentPath"],
            "pageNo": currentData["currentPage"] + 1,
            "orderBy": "fileName_asc",
        }).then(resp => {
            console.log(resp)
            if (resp.success) {
                let list = [...(currentData.files || [])]
                list.push(...(resp.data.files || []))
                const ret = {...resp.data, files: list}
                this.dispatch(FileActions.onLoaded(ret))
            } else if (resp.message === "RetryLaterAgain") {
                setTimeout(() => this.loadMore(currentData), 200)
            } else {
                this.dispatch(FileActions.onLoaded({}))
            }
        })
    }

    render() {
        const {initLoading, moreLoading, data} = this.props;
        let files = [...(data.files || [])]
        if (moreLoading) {
            files.push({"loading": true}, {"loading": true}, {"loading": true})
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
                    margin: '20px -30px',
                }}>
                    <Breadcrumb.Item key={"/"} style={{cursor: "pointer"}} onClick={e => this.loadInit("/")}>
                        <HomeOutlined/>
                    </Breadcrumb.Item>
                    {data.nav?.map((item, index) => {
                        return index === data.nav.length - 1 ?
                            <Breadcrumb.Item key={item.path}>
                                {item.name}
                            </Breadcrumb.Item>
                            :
                            <Breadcrumb.Item key={item.path} style={{cursor: "pointer"}}
                                             onClick={e => this.loadInit(item.path)}>
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
                    loadMore={this.loadMoreBtn(initLoading, moreLoading, data)}
                    dataSource={files}
                    renderItem={(item) => (
                        <List.Item key={item.path} style={{cursor: "pointer"}}
                                   onClick={e => this.onClickFileItem(item)}>
                            {item.loading
                                ? <Skeleton avatar title={false} loading={item.loading} active/>
                                : <div style={{display: "flex"}}>
                                    {this.fileThumb(item)}
                                    <div>
                                        <div>{item.name}</div>
                                        <div style={{color: "gray"}}>{item.modTime} {item.size}</div>
                                    </div>
                                </div>}
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
