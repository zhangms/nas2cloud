import React from 'react';
import {connect} from "react-redux";
import {Avatar, Breadcrumb, Button, Col, Dropdown, Image, Layout, List, Row, Skeleton, Space} from "antd";
import {Content, Header} from "antd/es/layout/layout";
import {FileActions} from "../../models/file";
import FileApi from "../../requests/api_file";
import API from "../../requests/api";
import {
    CloudUploadOutlined,
    FileExcelOutlined,
    FileOutlined,
    FilePdfOutlined,
    FilePptOutlined,
    FileTextOutlined,
    FileWordOutlined,
    FileZipFilled,
    FolderOutlined,
    HomeOutlined,
    PlusOutlined
} from "@ant-design/icons";

import FolderCreateForm from "./CreateFolderModal";

class FileManager extends React.Component {

    constructor(props) {
        super(props);
    }

    componentDidMount() {
        const {path, orderBy} = this.props
        this.loading({
            path, orderBy
        })
    }

    loading(request) {
        const {dispatch} = this.props
        dispatch(FileActions.changeState({
            initLoading: true,
            ...request
        }))
        FileApi.walk({
            pageNo: 0,
            ...request
        }).then(resp => {
            console.log(resp)
            if (resp.success) {
                dispatch(FileActions.onLoaded(resp.data))
            } else if (resp.message === "RetryLaterAgain") {
                setTimeout(() => this.loading(request), 200)
            } else {
                dispatch(FileActions.onLoaded({}))
            }
        })
    }

    isPreviewAble(item) {
        return item.type === "FILE" && item["thumbnail"]?.length > 0
    }

    fileItemView(item) {
        return this.isPreviewAble(item)
            ? this.fileItemViewWithPreview(item)
            : this.fileItemWithoutPreview(item)
    }

    fileItemViewWithPreview(item) {
        const src = API.fullUrl(encodeURI(item["thumbnail"]))
        const preview = API.fullUrl(encodeURI(item["path"]))
        return this.fileItemViewInner(item,
            <Image style={{marginRight: 10, width: 30, height: 30}}
                   src={src}
                   preview={{
                       src: preview,
                   }}
            />)
    }

    fileItemWithoutPreview(item) {
        return this.fileItemViewInner(item,
            <Avatar style={{marginRight: 10}} shape={"square"}
                    icon={this.getItemIcon(item)}/>, 0)
    }

    fileItemViewInner(item, avatarComp) {
        return <List.Item key={item.path}
                          style={{cursor: "pointer"}}
                          onClick={() => this.onClickFileItem(item)}>
            {item.loading
                ? <Skeleton avatar title={false} loading={item.loading} active/>
                : <div style={{display: "flex"}}>
                    {avatarComp}
                    <div>
                        <div>{item.name}</div>
                        <div style={{color: "gray"}}>{item["modTime"]} {item.size}</div>
                    </div>
                </div>
            }
        </List.Item>
    }

    getItemIcon(item) {
        if (item.type === "DIR") {
            return <FolderOutlined/>
        } else if (item.ext === ".PDF") {
            return <FilePdfOutlined/>
        } else if (item.ext === ".XLS" || item.ext === ".XLSX") {
            return <FileExcelOutlined/>
        } else if (item.ext === ".PPT" || item.ext === ".PPTX") {
            return <FilePptOutlined/>
        } else if (item.ext === ".DOC" || item.ext === ".DOCX") {
            return <FileWordOutlined/>
        } else if (item.ext === ".TXT") {
            return <FileTextOutlined/>
        } else if (item.ext === ".ZIP") {
            return <FileZipFilled/>
        } else {
            return <FileOutlined/>
        }
    }

    onClickFileItem(item) {
        const {orderBy} = this.props
        if (item.type === "DIR") {
            this.loading({
                path: item.path,
                orderBy: orderBy
            })
        }
    }

    loadMoreBtn() {
        const {initLoading, moreLoading, data} = this.props
        if (initLoading || moreLoading || data.total <= data.currentIndex) {
            return null
        }
        return <div style={{
            textAlign: 'center',
            marginTop: 12,
            height: 32,
            lineHeight: '32px',
        }}>
            <Button onClick={() => this.loadMore()}>loading more</Button>
        </div>
    }

    loadMore() {
        const {dispatch, currentPath, data, orderBy} = this.props
        dispatch(FileActions.changeState({moreLoading: true}))
        FileApi.walk({
            path: currentPath,
            pageNo: data.currentPage + 1,
            orderBy: orderBy,
        }).then(resp => {
            console.log(resp)
            if (resp.success) {
                dispatch(FileActions.onLoadMore(resp.data))
            } else if (resp.message === "RetryLaterAgain") {
                setTimeout(() => this.loadMore(), 200)
            } else {
                dispatch(FileActions.onLoadMore({}))
            }
        })
    }

    breadcrumb() {
        const {data, orderBy} = this.props
        return <Breadcrumb style={{margin: '20px -30px'}}>
            <Breadcrumb.Item key={"/"} style={{cursor: "pointer"}} onClick={() => this.loading({
                path: "/",
                orderBy: orderBy
            })}>
                <HomeOutlined/>
            </Breadcrumb.Item>
            {data.nav?.map((item, index) => {
                return index === data.nav.length - 1
                    ? <Breadcrumb.Item key={item.path}>
                        {item.name}
                    </Breadcrumb.Item>
                    : <Breadcrumb.Item key={item.path} style={{cursor: "pointer"}}
                                       onClick={() => this.loading({
                                           path: item.path,
                                           orderBy: orderBy
                                       })}>
                        {item.name}
                    </Breadcrumb.Item>
            })}
        </Breadcrumb>
    }

    orderByView() {
        const orderByMenus = [{
            key: 'fileName_asc',
            label: "file name asc",
        }, {
            key: 'fileName_desc',
            label: "file name desc",
        }, {
            key: 'size_asc',
            label: "file size asc",
        }, {
            key: 'size_desc',
            label: "file size desc",
        }, {
            key: 'time_asc',
            label: "file time asc",
        }, {
            key: 'time_desc',
            label: "file time desc",
        }];

        const {orderBy} = this.props
        return <Dropdown menu={{
            items: orderByMenus,
            onClick: (e) => this.onClickOrderBy(e),
            selectedKeys: [orderBy]
        }}>
            <a onClick={(e) => e.preventDefault()}>
                OrderBy
            </a>
        </Dropdown>
    }

    onClickOrderBy(e) {
        const {path} = this.props
        this.loading({
            path: path,
            orderBy: e.key
        })
    }

    actionView() {
        const actionMenus = [{
            key: 'createFolder',
            label: "create folder",
            icon: <PlusOutlined/>
        }, {
            key: 'addFile',
            label: "add file",
            icon: <CloudUploadOutlined/>
        }];
        return <Dropdown menu={{
            items: actionMenus,
            onClick: e => this.onClickAction(e)
        }}>
            <a onClick={(e) => e.preventDefault()}>
                Operation
            </a>
        </Dropdown>
    }

    onClickAction(e) {
        if (e.key === "createFolder") {
            this.setCreateFolderVisible(true)
        } else if (e.key === "addFile") {
            this.showAddFile()
        }
    }

    setCreateFolderVisible(visible) {
        const {dispatch} = this.props;
        dispatch(FileActions.changeState({createFolder: visible, initLoading: false, moreLoading: false}))
    }

    showAddFile() {
    }

    createFolderModal() {
        const {createFolder} = this.props;
        return <FolderCreateForm
            open={createFolder}
            onCreate={(value) => this.createFolder(value)}
            onCancel={() => this.setCreateFolderVisible(false)}
        />
    }

    createFolder(value) {
        const {dispatch, path} = this.props;
        dispatch(FileActions.changeState({createFolder: false, initLoading: true}))
        FileApi.createFolder({
            path: path,
            folderName: value["folderName"]
        }).then(resp => {
            if (resp.success) {
                setTimeout(() => this.loading({path: path, orderBy: "time_desc"}), 100)
            } else {
                alert(resp.message)
                dispatch(FileActions.changeState({createFolder: false, initLoading: false}))
            }
        })
    }

    render() {
        const {data, moreLoading, initLoading} = this.props;
        let files = [...(data?.files || [])]
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
                <Row gutter={16}>
                    <Col span={16}>
                        {this.breadcrumb()}
                    </Col>
                    <Col span={4}>
                        <Space size={"middle"}>
                            {this.orderByView()}
                            {this.actionView()}
                        </Space>
                    </Col>
                </Row>
            </Header>
            <Content style={{
                background: "white",
                paddingTop: 10
            }}>
                <Image.PreviewGroup>
                    <List
                        loading={initLoading}
                        itemLayout="horizontal"
                        size={"small"}
                        loadMore={this.loadMoreBtn()}
                        dataSource={files}
                        renderItem={(item) => (
                            this.fileItemView(item)
                        )}
                    />
                </Image.PreviewGroup>
                {this.createFolderModal()}
            </Content>
        </Layout>
    }
}

export default FileManager = connect(function (state) {
    return {...state.File}
})(FileManager)
