package com.controller;

import com.alibaba.druid.sql.visitor.functions.If;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.mapper.TbUserFileMapper;
import com.pojo.*;
import com.service.SystemFileService;
import com.service.UserFileService;
import com.sun.mail.imap.protocol.ID;
import com.utils.FtpUtil;
import com.utils.MD5Util;
import org.apache.commons.lang.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.*;
import java.lang.reflect.Type;
import java.math.BigDecimal;
import java.net.URL;
import java.net.URLEncoder;
import java.text.DecimalFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.UUID;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

/**
 * @Auther: zayvion
 * @Date: 2019-08-27 08:58
 * @Description:系统文件controller
 */
@Controller
@RequestMapping("/sysfile")
public class SystemFileController {

    @Autowired
    private SystemFileService systemFileService;
    @Autowired
    private UserFileService userFileService;
    @Autowired
    private TbUserFileMapper userFileMapper;
    private InputStream in = null;

    @RequestMapping("/upload")
    public String uploadFile(HttpSession session, @RequestParam("files") MultipartFile file, Model model, Long folder_id) throws IOException {
        TbUser user = (TbUser) session.getAttribute("onlineuser");
        // session没有用户信息直接返回错误信息
        if (user == null) {
            model.addAttribute("msg", "登录信息异常，请退出后重新登录！");
            return "error";
        }
        if (file != null) {
            // 先获得文件的大小，看看是否有空间
            long size = file.getSize();
            System.out.println(size);
            Long diskTotalSize = (Long) session.getAttribute("TotalSize");
            String userTotalSize = (String) session.getAttribute("userTotalSize");
            if (diskTotalSize - Double.parseDouble(userTotalSize) < size / 1024 / 1000) {
                model.addAttribute("msg", "您云盘的空间不足，成为超级用户尊享超大空间！");
                return "error";
            }

            /**
             * 拿到文件应先判断是否之前有用户上传过
             */
            String fileMd5 = MD5Util.getMd5File(file.getInputStream());
            List<TbSystemFile> compareFile = systemFileService.useMd5ToCompareFile(fileMd5);
            if (compareFile.size() != 0) {
                System.out.println("存在相同文件，不需要上传");
                TbSystemFile existFile = compareFile.get(0);
                TbUserFile userFile = new TbUserFile();
                userFile.setBelongUser(user.getUserId());
                userFile.setFileSize(existFile.getFileSize());
                userFile.setFileType(existFile.getFileType());
                int sameNameFile = userFileService.getSameNameFile(file.getOriginalFilename(), user.getUserId(), folder_id);
                if (sameNameFile > 0) {
                    model.addAttribute("msg", "云端有相同文件名文件，请重新上传！");
                    return "error";
                } else {
                    userFile.setUserFileName(file.getOriginalFilename());
                }
                userFile.setUserSysfileId(existFile.getFileId());
                userFile.setFileLocation(folder_id);
                userFileService.addFile(userFile);
                TbUserFileExample userFileExample = new TbUserFileExample();
                TbUserFileExample.Criteria fileExampleCriteria = userFileExample.createCriteria();
                fileExampleCriteria.andBelongUserEqualTo(user.getUserId());
                List<TbUserFile> tbUserFiles = userFileMapper.selectByExample(userFileExample);
                double sum = 0.0;
                for (TbUserFile tbUserFile : tbUserFiles) {
                    sum = sum + tbUserFile.getFileSize().doubleValue();
                }
                DecimalFormat decimalFormat = new DecimalFormat(".0");
                String format = decimalFormat.format(sum / 1024);
                session.setAttribute("userTotalSize", format);
                session.setAttribute("TotalSize", user.getDriveSize() / 1024);
                session.setAttribute("sizePresent", decimalFormat.format(sum / 1024 / (user.getDriveSize() / 1024) * 100));
                return "/views/home/console";
            }
            System.out.println(file.getOriginalFilename());
            String oldFileName = file.getOriginalFilename();
            // 文件扩展名开始的下标
            int dotIndex = oldFileName.indexOf(".");
            if (dotIndex == 0) {
                model.addAttribute("msg", "不支持的文件类型，请重试！");
                return "error";
            }
            String extension = oldFileName.substring(dotIndex);
            String newName = UUID.randomUUID().toString().substring(0, 15) + extension;
            String path = getDate();
            System.out.println(newName);
            System.out.println(extension);
            // 保存文件
            try {
                FtpUtil.uploadFile("182.254.180.106", 21, "image", "image", "/img", path, newName, file.getInputStream());
            } catch (Exception e) {
                e.printStackTrace();
            }
            /**
             * 写入数据库
             */
            TbSystemFile systemFile = new TbSystemFile();
            systemFile.setFileName(newName);
            systemFile.setFileSize(BigDecimal.valueOf(size / 1024));
            systemFile.setFileMd5(fileMd5);
            systemFile.setUploadUser(user.getUserId());
            systemFile.setFileUrl("http://image.lzllzl.cn/img/" + path + "/" + newName);
            // 根据文件扩展名判断类型
            if (extension.toLowerCase().equals(".jpg") || extension.toLowerCase().equals(".png") || extension.toLowerCase().equals(".gif") || extension.toLowerCase().equals(".bmp")) {
                systemFile.setFileType("1");
            } else if (extension.toLowerCase().equals(".mp3") || extension.toLowerCase().equals(".wav") || extension.toLowerCase().equals(".flac") || extension.toLowerCase().equals(".wma")) {
                systemFile.setFileType("2");
            } else if (extension.toLowerCase().equals(".mp4") || extension.toLowerCase().equals(".avi") || extension.toLowerCase().equals(".flv") || extension.toLowerCase().equals(".mov")) {
                systemFile.setFileType("3");
            } else if (extension.toLowerCase().equals(".doc") || extension.toLowerCase().equals(".docx") || extension.toLowerCase().equals(".txt") || extension.toLowerCase().equals(".ppt") || extension.toLowerCase().equals(".pptx") || extension.toLowerCase().equals(".xls") || extension.toLowerCase().equals(".xlsx") || extension.toLowerCase().equals(".pdf")) {
                systemFile.setFileType("4");
            } else {
                systemFile.setFileType("5");
            }
            long newFileId = systemFileService.addFile(systemFile);
            TbUserFile userFile = new TbUserFile();
            userFile.setBelongUser(user.getUserId());
            userFile.setFileSize(systemFile.getFileSize());
            userFile.setFileType(systemFile.getFileType());
            userFile.setUserFileName(file.getOriginalFilename());
            userFile.setUserSysfileId(newFileId);
            userFile.setFileLocation(folder_id);
            userFileService.addFile(userFile);
            TbUserFileExample userFileExample = new TbUserFileExample();
            TbUserFileExample.Criteria fileExampleCriteria = userFileExample.createCriteria();
            fileExampleCriteria.andBelongUserEqualTo(user.getUserId());
            List<TbUserFile> tbUserFiles = userFileMapper.selectByExample(userFileExample);
            double sum = 0.0;
            for (TbUserFile tbUserFile : tbUserFiles) {
                sum = sum + tbUserFile.getFileSize().doubleValue();
            }
            DecimalFormat decimalFormat = new DecimalFormat(".0");
            String format = decimalFormat.format(sum / 1024);
            session.setAttribute("userTotalSize", format);
            session.setAttribute("TotalSize", user.getDriveSize() / 1024);
            session.setAttribute("sizePresent", decimalFormat.format(sum / 1024 / (user.getDriveSize() / 1024) * 100));
            return "/views/home/console";
        } else {
            model.addAttribute("msg", "上传发生错误，青重试！");
            return "error";
        }
    }

    /**
     * 下载
     *
     * @param request
     * @param response
     * @param userFileId 前台传来的需要下载文件的ID
     * @param model
     * @return
     */
    @RequestMapping("/download")
    public String download(HttpServletRequest request, HttpServletResponse response, String userFileId, Model model, String downObjs) throws Exception {
        String[] files = null;
        Type type = new TypeToken<ArrayList<FolderAndFile>>() {}.getType();
        ArrayList<FolderAndFile> downloadObj = new Gson().fromJson(downObjs, type);
        for (FolderAndFile folderAndFile : downloadObj) {
            if (downloadObj.size() == 1 && !folderAndFile.getFileType().equals("0")) {
                TbUserFile file = userFileService.getUserFile(folderAndFile.getId());
                TbSystemFile systemFile = systemFileService.getSystemFile(file.getUserSysfileId());
                String fileName = file.getUserFileName();
                try {
                    //获取文件地址
                    URL internetUrl = new URL(systemFile.getFileUrl());
                    //将文件读入文件流
                    in = internetUrl.openStream();
                    //获得浏览器代理信息
                    final String userAgent = request.getHeader("USER-AGENT");
                    //判断浏览器代理并分别设置响应给浏览器的编码格式
                    String finalFileName = null;
                    if (StringUtils.contains(userAgent, "MSIE") || StringUtils.contains(userAgent, "Trident")) {//IE浏览器
                        finalFileName = URLEncoder.encode(fileName, "UTF8");
                        System.out.println("IE浏览器");
                    } else if (StringUtils.contains(userAgent, "Mozilla")) {//google,火狐浏览器
                        finalFileName = new String(fileName.getBytes(), "ISO8859-1");
                    } else {
                        finalFileName = URLEncoder.encode(fileName, "UTF8");//其他浏览器
                    }
                    //设置HTTP响应头
                    response.reset();// 重置响应头
                    response.setContentType("application/x-download");//告知浏览器下载文件，而不是直接打开，浏览器默认为打开
                    response.addHeader("Content-Disposition", "attachment;filename=\"" + finalFileName + "\"");//下载文件的名称

                    // 循环取出流中的数据
                    byte[] b = new byte[1024];
                    int len;
                    while ((len = in.read(b)) > 0) {
                        response.getOutputStream().write(b, 0, len);
                    }
                    in.close();
                    response.getOutputStream().close();
                } catch (Exception e) {
                    e.printStackTrace();
                }
                return null;
            } else if (downloadObj.size() == 1 && folderAndFile.getFileType().equals("0")) {
                List<TbUserFile> folderFiles = userFileService.getFolderFiles(folderAndFile.getId());
                for (int i = 0; i < folderFiles.size(); i++) {
                    TbSystemFile systemFile = systemFileService.getSystemFile(folderFiles.get(i).getUserSysfileId());
                    String fileName = folderFiles.get(0).getUserFileName();
                    // 获取下载地址
                    files = new String[folderFiles.size()];
                    for (int j = 0; j < folderFiles.size(); j++) {
                        TbUserFile userFile = userFileService.getUserFile(folderFiles.get(j).getUserfileId());
                        TbSystemFile sysFile = systemFileService.getSystemFile(userFile.getUserSysfileId());
                        files[j] = sysFile.getFileUrl();
                    }
                }
                // 文件的名称
                String downloadFilename = folderFiles.size() + "个文件.zip";
                downloadFilename = URLEncoder.encode(downloadFilename, "UTF-8");//转换中文否则可能会产生乱码
                response.setContentType("application/octet-stream");// 指明response的返回对象是文件流
                response.setHeader("Content-Disposition", "attachment;filename=" + downloadFilename);// 设置在下载框默认显示的文件名
                ZipOutputStream zos = new ZipOutputStream(response.getOutputStream());
                for (int k = 0; k < files.length; k++) {
                    URL url = new URL(files[k]);
                    String extession = files[k].substring(files[k].lastIndexOf("."));
                    zos.putNextEntry(new ZipEntry(k + extession));
                    //FileInputStream fis = new FileInputStream(new File(files[i]));
                    InputStream fis = url.openConnection().getInputStream();
                    byte[] buffer = new byte[1024];
                    int r = 0;
                    while ((r = fis.read(buffer)) != -1) {
                        zos.write(buffer, 0, r);
                    }
                    fis.close();
                }
                zos.flush();
                zos.close();

                return null;
            } else if (downloadObj.size() > 1 && !folderAndFile.getFileType().equals("0")) {
                for (int i = 0; i < downloadObj.size(); i++) {

                }
                // 获取下载地址
                files = new String[downloadObj.size()];
                for (int j = 0; j < downloadObj.size(); j++) {
                    TbUserFile userFile = userFileService.getUserFile(downloadObj.get(j).getId());
                    TbSystemFile sysFile = systemFileService.getSystemFile(userFile.getUserSysfileId());
                    files[j] = sysFile.getFileUrl();
                }
                // 文件的名称
                String downloadFilename = downloadObj.size() + "个文件.zip";
                downloadFilename = URLEncoder.encode(downloadFilename, "UTF-8");//转换中文否则可能会产生乱码
                response.setContentType("application/octet-stream");// 指明response的返回对象是文件流
                response.setHeader("Content-Disposition", "attachment;filename=" + downloadFilename);// 设置在下载框默认显示的文件名
                ZipOutputStream zos = new ZipOutputStream(response.getOutputStream());
                for (int k = 0; k < files.length; k++) {
                    URL url = new URL(files[k]);
                    String extession = files[k].substring(files[k].lastIndexOf("."));
                    zos.putNextEntry(new ZipEntry(k + extession));
                    //FileInputStream fis = new FileInputStream(new File(files[i]));
                    InputStream fis = url.openConnection().getInputStream();
                    byte[] buffer = new byte[1024];
                    int r = 0;
                    while ((r = fis.read(buffer)) != -1) {
                        zos.write(buffer, 0, r);
                    }
                    fis.close();
                }
                zos.flush();
                zos.close();
            } else {
                model.addAttribute("msg", "暂不支持这种形式的下载请求，系统持续升级中！");
                return "error";
            }
        }
        return null;
    }


    /**
     * 获取当前日期作为文件夹名
     *
     * @return
     */
    public String getDate() {
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
        String format = sdf.format(new Date());
        return format;
    }


}
