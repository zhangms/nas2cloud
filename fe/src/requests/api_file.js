import API from "./api";

const FileApi = {

    walk: async function (body) {
        return await API.POST("/store/walk", body)
    }

}

export default FileApi