import API from "./api";

const FileApi = {

    walk: async function (body) {
        return await API.POST("/api/store/walk", body)
    },

    createFolder: async function (body) {
        return await API.POST("/api/store/createFolder", body)
    },

    delete: async function (body) {
        return await API.POST("/api/store/deleteFiles", body)
    }

}

export default FileApi