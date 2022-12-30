import API from "./api";

const FileApi = {

    walk: async function (path) {
        return await API.POST("/store/walk", {
            "path": path
        })
    }

}

export default FileApi