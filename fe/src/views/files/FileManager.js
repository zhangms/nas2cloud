import React from 'react';
import {connect} from "react-redux";
import {Avatar, Breadcrumb, Button, Col, Dropdown, Image, Layout, List, Row, Skeleton, Space} from "antd";
import {Content, Header} from "antd/es/layout/layout";
import {FileActions} from "../../models/file";
import FileApi from "../../requests/api_file";
import API from "../../requests/api";
import {
    DownOutlined,
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


class FileManager extends React.Component {

    constructor(props) {
        super(props);
        this.orderByMenus = [{
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
    }

    componentDidMount() {
        this.loading(this.props.currentPath)
    }

    loading(path) {
        this.props.dispatch(FileActions.changeState({initLoading: true, currentPath: path}))
        FileApi.walk({
            path: path,
            pageNo: 0,
            orderBy: this.props.orderBy,
        }).then(resp => {
            console.log(resp)
            if (resp.success) {
                this.props.dispatch(FileActions.onLoaded(resp.data))
            } else if (resp.message === "RetryLaterAgain") {
                setTimeout(() => this.loading(path), 200)
            } else {
                this.props.dispatch(FileActions.onLoaded({}))
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
                          onClick={e => this.onClickFileItem(item)}>
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
        if (item.type === "DIR") {
            this.loading(item.path)
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
            <Button onClick={e => this.loadMore()}>loading more</Button>
        </div>
    }

    loadMore() {
        this.props.dispatch(FileActions.changeState({moreLoading: true}))
        FileApi.walk({
            path: this.props.currentPath,
            pageNo: this.props.data.currentPage + 1,
            orderBy: this.props.orderBy,
        }).then(resp => {
            console.log(resp)
            if (resp.success) {
                this.props.dispatch(FileActions.onLoadMore(resp.data))
            } else if (resp.message === "RetryLaterAgain") {
                setTimeout(() => this.loadMore(), 200)
            } else {
                this.props.dispatch(FileActions.onLoadMore({}))
            }
        })
    }

    breadcrumb() {
        const {data} = this.props
        return <Breadcrumb style={{margin: '20px -30px'}}>
            <Breadcrumb.Item key={"/"} style={{cursor: "pointer"}} onClick={e => this.loading("/")}>
                <HomeOutlined/>
            </Breadcrumb.Item>
            {data.nav?.map((item, index) => {
                return index === data.nav.length - 1
                    ? <Breadcrumb.Item key={item.path}>
                        {item.name}
                    </Breadcrumb.Item>
                    : <Breadcrumb.Item key={item.path} style={{cursor: "pointer"}}
                                       onClick={e => this.loading(item.path)}>
                        {item.name}
                    </Breadcrumb.Item>
            })}
        </Breadcrumb>
    }

    orderByView() {
        return <Dropdown menu={{
            items: this.orderByMenus,
            onClick: (e) => this.onClickOrderBy(e),
            selectedKeys: [this.props.orderBy]
        }}>
            <a onClick={(e) => e.preventDefault()}>
                <Space>
                    OrderBy
                    <DownOutlined/>
                </Space>
            </a>
        </Dropdown>
    }

    onClickOrderBy(e) {
        this.props.dispatch(FileActions.changeState({orderBy: e.key}))
        this.loading(this.props.currentPath)
    }

    render() {
        let files = [...(this.props.data?.files || [])]
        if (this.props.moreLoading) {
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
                    <Col span={8}>
                        {this.orderByView()}
                    </Col>
                </Row>
            </Header>
            <Content style={{
                background: "white",
                paddingTop: 10
            }}>
                <Image.PreviewGroup>
                    <List
                        loading={this.props.initLoading}
                        itemLayout="horizontal"
                        size={"small"}
                        loadMore={this.loadMoreBtn()}
                        dataSource={files}
                        renderItem={(item) => (
                            this.fileItemView(item)
                        )}
                    />
                </Image.PreviewGroup>
            </Content>
        </Layout>
    }
}

export default FileManager = connect(function (state) {
    return {...state.File}
})(FileManager)
