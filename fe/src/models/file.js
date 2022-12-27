import {createSlice} from "@reduxjs/toolkit";

const fileSlice = createSlice({
    name: "fileSlice",
    initialState: {
        initLoading: true,
        data: []
    },
    reducers: {
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