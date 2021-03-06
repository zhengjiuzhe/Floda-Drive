<%--
  User: dc
  Date: 2019/8/26
  Time: 9:27
--%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@page isELIgnored="false" %>
<html>
<%
    String path = request.getContextPath();
    String basePath = request.getScheme() + "://" + request.getServerName() + ":" + request.getServerPort() + path + "/";
%>
<head>
    <base href="<%=basePath%>">
    <meta charset="utf-8">
    <title>回收站</title>
    <meta name="renderer" content="webkit">
    <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
    <meta name="viewport"
          content="width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, user-scalable=0">
    <link rel="stylesheet" href="../../layuiadmin/layui/css/layui.css" media="all">
    <link rel="stylesheet" href="../../layuiadmin/style/admin.css" media="all">
    <link href="../../layuiadmin/style/font-awesome.min.css" rel="stylesheet">
    <style>
        i {
            margin-right: 5px;
        }
        .layui-card-header button{
            border:1px solid #c3eaff;
            color: #0098ea;
            background-color: #ffffff;
        }
        .layui-card-header button:hover{
            color: #0098ea;
        }
        .layui-card-header .layui-btn-group button,.layui-card-header .layui-btn-group a {
            border-color: #c3eaff;
            color: #0098ea;
        }
        .layui-card-header .layui-btn-group button:first-child {
            border-color: #c3eaff;
            color: #0098ea;
        }
        .layui-card-header .layui-btn-group a:hover {
            border-color: #c3eaff;
            color: #0098ea;
        }
        .layui-table-cell .layui-form-checkbox[lay-skin=primary] {
            top: 6px;
        }
        .layui-form-checked[lay-skin=primary] i {
            border-color: #0098ea;
            background-color: transparent;
            color: #09AAFF;
            font-weight: bolder;
        }
        .layui-form-checkbox[lay-skin=primary]:hover i {
            border-color: #0098ea;
            color: #09AAFF;
        }
        .folderList{
            font-size: 12px;
            margin: 5px 0;
            color: #1E9FFF;
        }
    </style>
</head>
<body>

<div class="layui-fluid">
    <div class="layui-row layui-col-space15">
        <div class="layui-col-md12">
            <div class="layui-card">
                <div class="layui-card-header">
                    <button type="button" class="layui-btn layui-btn-sm layui-btn-normal" onclick="empty()" style="float: right;margin-top: 6px">
                        <i class="fa fa-upload"></i>清空回收站
                    </button>
                    <div class="layui-btn-group layui-hide">
                        <button type="button" class="layui-btn layui-btn-sm layui-btn-primary" onclick="reduction()">
                            <i class="fa fa-refresh"></i>还原
                        </button>
                        <a type="button" class="layui-btn layui-btn-sm layui-btn-primary" onclick="del()">
                            <i class="fa fa-download"></i>删除
                        </a>
                    </div>
                </div>
                <div class="layui-card-body">
                    <table class="layui-hide" id="test-table-checkbox" lay-filter="test-table-checkbox"></table>
                </div>
            </div>
        </div>
    </div>
</div>

<script src="../../layuiadmin/layui/layui.js?t=1"></script>
<script src="https://cdn.jsdelivr.net/npm/jquery@1.12.4/dist/jquery.min.js"></script>
<script src="../../layuiadmin/lib/spotlight/js/spotlight.bundle.js"></script>
<script>
    var table,layer,tableIns,folderId=0,gallery = [],count = 0;

    layui.config({
        base: '../../layuiadmin/' //静态资源所在路径
    }).extend({
        index: 'lib/index' //主入口模块
    }).use(['index', 'table'], function () {
            table = layui.table,
            layer = layui.layer;

        tableIns = table.render({
            elem: '#test-table-checkbox'
            , skin: 'row'
            , url: 'recycle/list'//获取数据的地方
            , where:{folder_father:folderId}//传递参数的地方
            , cellMinWidth: 80 //全局定义常规单元格的最小宽度，layui 2.2.1 新增
            , id:'test-table-checkbox'
            , cols: [
                [{type: 'checkbox'}
                , {
                    field: 'userFileName',
                    width: 600,
                    title: '文件名',
                    templet: function (d) {
                        console.log(d)
                        var icon = "";
                        switch (d.fileType) {
                            case '0':
                                icon = "<i class='fa fa-folder' style='font-size:18px;color:rgb(255,214,89);margin:8px 5px 0 0'></i>";
                                break;
                            case '1':
                                icon = "<i class='fa fa-file-photo-o' style='font-size:18px;color:rgb(255,119,67);margin:8px 5px 0 0'></i>";
                                break;
                            case '2':
                                icon = "<i class='fa fa-file-audio-o' style='font-size:18px;color:rgb(129,131,241);margin:8px 5px 0 0'></i>";
                                break;
                            case '3':
                                icon = "<i class='fa fa-file-video-o' style='font-size:18px;color:rgb(129,131,241);margin:8px 5px 0 0'></i>";
                                break;
                            case '4':
                                icon = "<i class='fa fa-file-text' style='font-size:18px;color:rgb(77,151,255);margin:8px 5px 0 0'></i>";
                                break;
                            case '5':
                                icon = "<i class='fa fa-file' style='font-size:18px;color:rgb(185,201,214);margin:8px 5px 0 0'></i>";
                                break;
                        }
                        return icon+d.userFileName;
                    }
                }
                , {
                    field: 'fileSize',
                    width: 160,
                    title: '大小',
                    templet: function (d) {
                        if (d.fileSize !== undefined){
                            if (d.fileSize >= 1024){
                                return (d.fileSize/1024).toFixed(1)+"MB";
                            }else {
                                return d.fileSize+"KB";
                            }
                        }else {
                            return '-';
                        }
                    },
                }
                , {
                    field: 'updatetime',
                    title: '修改日期',
                    templet: "<div>{{layui.util.toDateString(d.updatetime, 'yyyy-MM-dd HH:mm:ss')}}</div>"
                }

            ]]
        });
        table.on('checkbox(test-table-checkbox)', function (obj) {
            var checkStatus = table.checkStatus('test-table-checkbox');
            //console.log("当前选中的个数："+checkStatus.data.length);//输出当前选中的个数
            //console.log("相关数据："+checkStatus.data); //选中行的相关数据
            //console.log("是否全选:"+checkStatus.isAll); //如果触发的是全选，则为：all，如果触发的是单选，则为：one
            if (checkStatus.data.length > 0) {
                $('.layui-btn-group').removeClass('layui-hide');
                if (checkStatus.data.length > 1) {
                    $('.layui-btn-group button').eq(3).addClass('layui-btn-disabled').attr("disabled", 'disabled');
                } else {
                    $('.layui-btn-group button').eq(3).removeClass('layui-btn-disabled').removeAttr('disabled');
                }
            } else {
                $('.layui-btn-group').addClass('layui-hide');
            }
        });
    });


    //还原
    function reduction(folder_father) {
        var jsonData = table.checkStatus('test-table-checkbox').data;
        var userfileIds = [];
        for (var i = 0; i < jsonData.length; i++){
            userfileIds.push(jsonData[i].userfileId);
        }
        console.log(JSON.stringify(userfileIds));
        layer.confirm('',{
            offset: '200px',
            content: '确认要把所选文件还原吗？',
            btnAlign: 'c',
            title:'确认还原',
            icon:2
        },function(index){
            $.post("recycle/restore",{userfileIds:JSON.stringify(userfileIds)},function (data,status) {
                if (data.status === 200){
                    layer.msg(data.data,{
                        icon:1,
                        offset: '200px'
                    });
                    //需改数据后表格局部刷新
                    tableIns.reload({
                        where: { //设定异步数据接口的额外参数，任意设
                            folder_father: folder_father
                        }
                    });
                    $('.layui-btn-group').addClass('layui-hide');
                }else {
                    layer.msg(data.msg,{
                        icon:2,
                        offset: '200px'
                    });
                }
            });
            layer.close(index);
        });
    }

    //删除
    function del(folder_father) {
        var jsonData = table.checkStatus('test-table-checkbox').data;
        var userfileIds = [];
        for (var i = 0; i < jsonData.length; i++){
            userfileIds.push(jsonData[i].userfileId);
        }
        console.log(JSON.stringify(userfileIds));
        layer.confirm('',{
            offset: '200px',
            content: '确认要把所选文件删除吗？',
            btnAlign: 'c',
            title:'确认删除',
            icon:2
        },function(index){
            $.post("recycle/del",{userfileIds:JSON.stringify(userfileIds)},function (data,status) {
                if (data.status === 200){
                    layer.msg(data.data,{
                        icon:1,
                        offset: '200px'
                    });
                    //需改数据后表格局部刷新
                    tableIns.reload({
                        where: { //设定异步数据接口的额外参数，任意设
                            folder_father: folder_father
                        }
                    });
                    $('.layui-btn-group').addClass('layui-hide');
                }else {
                    layer.msg(data.msg,{
                        icon:2,
                        offset: '200px'
                    });
                }
            });
            layer.close(index);
        });
    }

    //清空
    function empty(folder_father) {
        layer.confirm('',{
            offset: '200px',
            content: '确认要清空所有文件吗？',
            btnAlign: 'c',
            title:'确认清空',
            icon:2
        },function(index){
            $.post("recycle/empty",function (data,status) {
                if (data.status === 200){
                    layer.msg(data.data,{
                        icon:1,
                        offset: '200px'
                    });
                    //需改数据后表格局部刷新
                    tableIns.reload({
                        where: { //设定异步数据接口的额外参数，任意设
                            folder_father: folder_father
                        }
                    });
                    $('.layui-btn-group').addClass('layui-hide');
                }else {
                    layer.msg(data.msg,{
                        icon:2,
                        offset: '200px'
                    });
                }
            });
            layer.close(index);
        });
    }
</script>
</body>
</html>