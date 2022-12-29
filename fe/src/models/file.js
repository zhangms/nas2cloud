import {createSlice} from "@reduxjs/toolkit";

const fileSlice = createSlice({
    name: "fileSlice",
    initialState: {
        initLoading: true,
        data: []
    },
    reducers: {
        showLoading: function (state, action) {
            return {...state, initLoading: true}
        },

        onLoaded: function (state, action) {
            return {
                initLoading: false,
                data: action.payload
            }
        }
    }
})

export const FileReducer = fileSlice.reducer
export const FileActions = fileSlice.actions