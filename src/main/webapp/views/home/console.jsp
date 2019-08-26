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
    <title>文件夹</title>
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

        .layui-card-header button:nth-of-type(2) {
            border-color: #c3eaff;
            color: #0098ea;
            margin-right: 10px;
        }

        .layui-card-header .layui-btn-group button {
            border-color: #c3eaff;
            color: #0098ea;
        }

        .layui-card-header .layui-btn-group button:first-child {
            border-color: #c3eaff;
            color: #0098ea;
        }

        .layui-card-header .layui-btn-group button:hover {
            border-color: #c3eaff;
            color: #0098ea;
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
        .layui-form-checked{
            margin-top: 10px;
        }
    </style>
</head>
<body>

<div class="layui-fluid">
    <div class="layui-row layui-col-space15">
        <div class="layui-col-md12">
            <div class="layui-card">
                <div class="layui-card-header">
                    <button type="button" class="layui-btn layui-btn-sm layui-btn-normal">
                        <i class="fa fa-upload"></i>文件上传
                    </button>
                    <button type="button" class="layui-btn layui-btn-sm layui-btn-primary">
                        <i class="fa fa-folder-o"></i>新建文件夹
                    </button>
                    <div class="layui-btn-group layui-hide">
                        <button type="button" class="layui-btn layui-btn-sm layui-btn-primary">
                            <i class="fa fa-share"></i>分享
                        </button>
                        <button type="button" class="layui-btn layui-btn-sm layui-btn-primary">
                            <i class="fa fa-trash"></i>删除
                        </button>
                        <button type="button" class="layui-btn layui-btn-sm layui-btn-primary">
                            <i class="fa fa-pencil"></i>重命名
                        </button>
                    </div>
                </div>
                <div class="layui-card-body">
                    <p style="font-size: 12px;margin: 5px 0">全部文件</p>
                    <table class="layui-hide" id="test-table-checkbox" lay-filter="test-table-checkbox"></table>
                </div>
            </div>
        </div>
    </div>
</div>

<script src="../../layuiadmin/layui/layui.js?t=1"></script>
<script src="https://cdn.jsdelivr.net/npm/jquery@1.12.4/dist/jquery.min.js"></script>
<script>
    layui.config({
        base: '../../layuiadmin/' //静态资源所在路径
    }).extend({
        index: 'lib/index' //主入口模块
    }).use(['index', 'table'], function () {
        var table = layui.table;

        table.render({
            elem: '#test-table-checkbox'
            , skin: 'row'
            , url: layui.setter.base + 'json/table/user.js'//获取数据的地方
            , cellMinWidth: 80 //全局定义常规单元格的最小宽度，layui 2.2.1 新增
            , cols: [[{type: 'checkbox'}
                , {field: 'folder', width: 600, title: '文件名', sort: true}
                , {field: 'size', width: 220, title: '大小', sort: true}
                , {field: 'updatetime', title: '修改日期', sort: true} //minWidth：局部定义当前单元格的最小宽度，layui 2.2.1 新增
            ]]
        });

        table.on('checkbox(test-table-checkbox)', function (obj) {
            var checkStatus = table.checkStatus('test-table-checkbox');
            //console.log("当前选中的个数："+checkStatus.data.length);//输出当前选中的个数
            //console.log("相关数据："+checkStatus.data); //选中行的相关数据
            //console.log("是否全选:"+checkStatus.isAll); //如果触发的是全选，则为：all，如果触发的是单选，则为：one
            if (checkStatus.data.length > 0){
                $('.layui-btn-group').removeClass('layui-hide');
                // if (checkStatus.data.length > 1){
                //
                // }
            }else {
                $('.layui-btn-group').addClass('layui-hide');
            }
        });
    });
</script>
</body>
</html>