import API from "./api";

const FileApi = {

    walk: async function (body) {
        return await API.POST("/store/walk", body)
    },

    createFolder: async function (body) {
        return await API.POST("/store/createFolder", body)
    },

    delete: async function (body) {
        return await API.POST("/store/deleteFiles", body)
    }

}

export default FileApi