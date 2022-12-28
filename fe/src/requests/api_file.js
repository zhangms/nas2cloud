import API from "./api";

const FileApi = {

    list: async function (path) {
        return await API.POST("/store/list", {
            "path": path
        })
    }

}

export default FileApi