rm(list = ls())
gc()
# setwd("~/test")
setwd("F:/07-CAUS/01-Linux-service/project_18DH-heterosis/Analysis/31-gwas_mph/test/code_for_epi/output/")
# setwd("/mnt/f/07-CAUS/01-Linux-service/project_18DH-heterosis/Analysis/31-gwas_mph/test")
# library(rbenchmark) # benchmark
library(bench)

# install.packages("combinat")                   # Install combinat package
# library("combinat") 
library(Rcpp)
sourceCpp(file = "../source/epi.cpp")
# library(data.table)
# library(foreach)
# library(doParallel)
# library(BiocParallel)
library(getopt)
# library(biglm)
library(bigmemory)

# 测试参数
trait = "PH"
load(file = "../data/Adata.RData")
load(file = "../data/Ddata.RData")
load(paste0("../data/trAdata_",trait,".RData"))
load(paste0("../data/trDdata_",trait,".RData"))
load(paste0("../data/TRAN_",trait,".RData"))
load(paste0("../data/Y_",trait,".RData"))
load(file = "../data/total_ma_names.rdata")
nmar=500
TRAN = TRAN
eff_type = "ad"
epi1 = Adata
epi2 = Ddata
trdata1 = trAdata
trdata2 = trDdata
# total_ma_names = total_ma_names
no_cores = 4

# combinat::combn(1:5,2)
# utils::combn(1:5,2)
# 
# combos <- combinat::combn(total_ma_names,2)
# combos2 <- utils::combn(total_ma_names,2)# 这个计数有问题
# 
# 
# utils::combn()
# count <- choose(2100000000,2)
# count2 <-   nCm(2100000000,2)# 这个计数有问题
# rMVP
remove_bigmatrix <- function(x, desc_suffix=".desc", bin_suffix=".bin") {
  name <- basename(x)
  path <- dirname(x)
  
  descfile <- paste0(x, desc_suffix)
  binfile  <- paste0(x, bin_suffix)
  
  remove_var <- function(binfile, envir) {
    for (v in ls(envir = envir)) {
      if (is(get(v, envir = envir), "big.matrix")) {
        desc <- describe(get(v, envir = envir))@description
        if (desc$filename == binfile) {
          rm(list = v, envir = envir)
          gc()
        }
      }
    }
  }
  
  # remove_var(binfile, globalenv())
  remove_var(binfile, as.environment(-1L))
  
  if (file.exists(descfile)) {
    file.remove(descfile)
  }
  if (file.exists(binfile)) {
    file.remove(binfile)
  }
}

# utils::combn()
# x=length(total_ma_names)
# m=2
big.combn <- function (x, m, FUN = NULL, simplify = TRUE, ...) 
{
  stopifnot(length(m) == 1L, is.numeric(m))
  if (m < 0) 
    stop("m < 0", domain = NA)
  if (is.numeric(x) && length(x) == 1L && x > 0 && trunc(x) == 
      x) 
    x <- seq_len(x)
  n <- length(x)
  if (n < m) 
    stop("n < m", domain = NA)
  x0 <- x
  if (simplify) {
    if (is.factor(x)) 
      x <- as.integer(x)
  }
  m <- as.integer(m)
  e <- 0
  h <- m
  a <- seq_len(m)
  nofun <- is.null(FUN)
  if (!nofun && !is.function(FUN)) 
    stop("'FUN' must be a function or NULL")
  len.r <- length(r <- if (nofun) x[a] else FUN(x[a], ...))
  count <- as.numeric(round(choose(n, m)))
  if (simplify) {
    dim.use <- if (nofun) 
      c(m, count)
    else {
      d <- dim(r)
      if (length(d) > 1L) 
        c(d, count)
      else if (len.r != 1L) 
        c(len.r, count)
      else c(d, count)
    }
  }
  if (simplify) {
    # out <- matrix(r, nrow = len.r, ncol = count)
    remove_bigmatrix("combn")
    out <- filebacked.big.matrix(
      nrow = len.r,
      ncol = count,
      type = "integer", # char是c++的单个字符
      backingfile = "combn.bin", 
      backingpath = dirname("combn"), 
      descriptorfile = "combn.des",
      dimnames = c(NULL, NULL)
    )
    out[,1] <- r
  } else {
    out <- vector("list", count)
    out[[1L]] <- r
  }
  if (m > 0) {
    i <- 2
    nmmp1 <- n - m + 1
    while (a[1] != nmmp1) {
      if (e < n - h) {
        h <- 1
        e <- a[m]
        j <- 1
      } else {
        e <- a[m - h]
        h <- h + 1
        j <- 1:h
      }
      a[m - h + j] <- e + j
      r <- if (nofun) {
        x[a]
      } else FUN(x[a], ...)
      if (simplify) {
        out[, i] <- r
      } else out[[i]] <- r
      i <- i + 1
    }
  }
  if (simplify) {
    if (is.factor(x0)) {
      levels(out) <- levels(x0)
      # class(out) <- class(x0)
    }
    # dim(out) <- dim.use
  }
  out
}

combos <- big.combn(length(total_ma_names),2)
nmar <- length(total_ma_names)
big.combn.epi <- function (x, m=2, nmar,FUN = NULL, simplify = TRUE, ...) 
{
  stopifnot(length(m) == 1L, is.numeric(m))
  if (m < 0) 
    stop("m < 0", domain = NA)
  if (is.numeric(x) && length(x) == 1L && x > 0 && trunc(x) == 
      x) 
    x <- seq_len(x)
  n <- length(x)
  if (n < m) 
    stop("n < m", domain = NA)
  x0 <- x
  if (simplify) {
    if (is.factor(x)) 
      x <- as.integer(x)
  }
  m <- as.integer(m)
  e <- 0
  h <- m
  a <- seq_len(m)
  nofun <- is.null(FUN)
  if (!nofun && !is.function(FUN)) 
    stop("'FUN' must be a function or NULL")
  len.r <- length(r <- if (nofun)
    c(x[a][1]+1L,
      as.integer(x[a][2]+nmar+1L),
      (x[a][1]+1L)*nmar-sum(0L:(x[a][1]-1L))+x[a][2]-x[a][1]+1L)
    else FUN(x[a], ...)
  )
  count <- as.numeric(round(choose(n, m)))
  if (simplify) {
    dim.use <- if (nofun) 
      c(m, count)
    else {
      d <- dim(r)
      if (length(d) > 1L) 
        c(d, count)
      else if (len.r != 1L) 
        c(len.r, count)
      else c(d, count)
    }
  }
  if (simplify) {
    # out <- matrix(r, nrow = len.r, ncol = count)
    remove_bigmatrix("combn.epi")
    out <- filebacked.big.matrix(
      nrow = len.r,
      ncol = count,
      type = "integer", # char是c++的单个字符
      backingfile = "combn.epi.bin", 
      backingpath = dirname("combn.epi"), 
      descriptorfile = "combn.epi.des",
      dimnames = c(NULL, NULL)
    )
    out[,1] <- r
  } else {
    out <- vector("list", count)
    out[[1L]] <- r
  }
  if (m > 0) {
    i <- 2
    nmmp1 <- n - m + 1
    while (a[1] != nmmp1) {
      if (e < n - h) {
        h <- 1
        e <- a[m]
        j <- 1
      } else {
        e <- a[m - h]
        h <- h + 1
        j <- 1:h
      }
      a[m - h + j] <- e + j
      r <- if (nofun) {
        # x[a]
        c(x[a][1]+1L,
          as.integer(x[a][2]+nmar+1L),
          (x[a][1]+1L)*nmar-sum(0L:(x[a][1]-1L))+x[a][2]-x[a][1]+1L)
      } else FUN(x[a], ...)
      if (simplify) {
        out[, i] <- r
      } else out[[i]] <- r
      i <- i + 1
    }
  }
  if (simplify) {
    if (is.factor(x0)) {
      levels(out) <- levels(x0)
      # class(out) <- class(x0)
    }
    # dim(out) <- dim.use
  }
  out
}
epi_index <- big.combn.epi(length(total_ma_names),2,nmar = nmar)

remove_bigmatrix("epi_data")
epi_data <- filebacked.big.matrix(
  nrow = nrow(TRAN),
  ncol = ncol(combos)+2*nmar+ncol(Y),
  type = "double", # char是c++的单个字符
  backingfile = "epi_data.bin",
  backingpath = dirname("epi_data"),
  descriptorfile = "epi_data.des",
  dimnames = c(NULL, NULL)
)

# 加载C++代码
# sourceCpp(file = "/mnt/f/07-CAUS/01-Linux-service/project_18DH-heterosis/Analysis/31-gwas_mph/test/code_for_epi/source/epi.cpp")
# sourceCpp(file = "f:/07-CAUS/01-Linux-service/project_18DH-heterosis/Analysis/31-gwas_mph/test/code_for_epi/source/epi.cpp")

# 调用 Rcpp 函数将 R 矩阵转换为 arma::mat
# epi1 <- convertRMatrixToArmaMat(epi1)
# epi2 <- convertRMatrixToArmaMat(epi2)
# TRAN <- convertRMatrixToArmaMat(TRAN)
epi1 <- TransferMatArma(epi1)
epi2 <- TransferMatArma(epi2)
TRAN <- TransferMatArma(TRAN)
# 预计算lm需要的数据
tryCatch({
  ca_epi_data(epi_data@address, combos@address, epi1, epi2, TRAN, 
              Y, trdata1,trdata2, threads = 4)
}, error = function(e) {
  print(e)
})
# rm(epi1,epi2,Y,trdata1,trdata2,trAdata,trDdata,TRAN,combos)
# gc()
# combos_index=combos[,2659]
# m=combos_index[1]
# n=combos_index[2]
# epidesign <- TRAN%*%(epi1[,m]*epi2[,n])
# subdata <- data.frame(y=Y,trdata1[,m],trdata2[,n],epi=epidesign)
# colnames(subdata)[2:3] <- total_ma_names[c(m,n)]
# 
# ## R subdata
# if(subdata[1,3]+subdata[1,4]==0){
#   print(subdata[,3]+subdata[,4],digits=22)
# }else{
#   print(subdata[1:5,3]+subdata[1:5,4],digits=22)
# }
# ## Rcpp subdata
# index <- epi_index[,2659]
# if(epi_data[1,index[2]]+epi_data[1,index[3]]==0){
#   print(epi_data[,index[2]]+epi_data[,index[3]],digits=22)
# }else{
#   print(epi_data[1:5,index],digits=22)
# }
# 
# fit.lm <- lm(as.formula(paste("y ~ -1 +",total_ma_names[m],"+",total_ma_names[n],"+ epi")),
#              data=subdata)
# print(summary(fit.lm)$coefficient,digits=22)

# lm
remove_bigmatrix("epi_eff")
epi_eff <- filebacked.big.matrix(
  nrow = nmar,
  ncol = nmar,
  type = "double", # char是c++的单个字符
  backingfile = "epi_eff.bin",
  backingpath = dirname("epi_eff"),
  descriptorfile = "epi_eff.des",
  dimnames = c(total_ma_names, total_ma_names)
)

remove_bigmatrix("epi_pval")
epi_pval <- filebacked.big.matrix(
  nrow = nmar,
  ncol = nmar,
  type = "double", # char是c++的单个字符
  backingfile = "epi_pval.bin",
  backingpath = dirname("epi_pval"),
  descriptorfile = "epi_pval.des",
  dimnames = c(total_ma_names, total_ma_names)
)

# 加载C++代码
# sourceCpp(file = "/mnt/f/07-CAUS/01-Linux-service/project_18DH-heterosis/Analysis/31-gwas_mph/test/code_for_epi/source/epi.cpp")
# sourceCpp(file = "f:/07-CAUS/01-Linux-service/project_18DH-heterosis/Analysis/31-gwas_mph/test/code_for_epi/source/epi.cpp")

# result <- ca_epi_pval_eff(epi_pval@address,epi_eff@address,epi_data@address,epi_index@address,1)


# 对于存在正交的标记编码，反应在trdata中是互为相反数，不该输出epi的系数。

# 计算pval eff
tryCatch({
  ca_epi_pval_eff(epi_pval@address,epi_eff@address,epi_data@address,epi_index@address,combos@address,4)
}, error = function(e) {
  print(e)
})

## rcpp muti-threads性能测试 ####
for_ad <- function(){
  # scan for additive-by-dominance epistatic effects
  
  res_eff <- matrix(0,nmar,nmar)
  rownames(res_eff) <- total_ma_names
  colnames(res_eff) <- total_ma_names
  res_pval <- res_eff
  
  for (m in 1:(nmar-1)) {
    for (n in (m+1):nmar) {
      epidesign <- TRAN%*%(Adata[,m]*Ddata[,n])
      subdata <- data.frame(y=Y,trAdata[,m],trDdata[,n],epi=epidesign)
      colnames(subdata)[2:3] <- total_ma_names[c(m,n)]
      # subdata[,2] <- as.factor(subdata[,2])
      # subdata[,3] <- as.factor(subdata[,3])
      # subdata[,4] <- as.factor(subdata[,4])
      fit.lm <- lm(as.formula(paste("y ~ -1 +",total_ma_names[m],"+",total_ma_names[n],"+ epi")),
                   data=subdata)
      infomat <- summary(fit.lm)$coefficient
      if ("epi"%in%rownames(infomat))
      {
        res_eff[m,n] <- summary(fit.lm)$coefficient["epi",1]
        res_pval[m,n] <- summary(fit.lm)$coefficient["epi",4]
      }else{
        res_pval[m,n] <- 1
      }
      # fit.lm <- biglm(as.formula(paste("y ~ -1 +",total_ma_names[m],"+",total_ma_names[n],"+ epi")),
      #              data=subdata)
      # infomat <- summary(fit.lm)$mat
      # if ("epi"%in%rownames(infomat))
      # {
      #   res_eff[m,n] <- summary(fit.lm)$mat["epi","Coef"]
      #   res_pval[m,n] <- summary(fit.lm)$mat["epi","p"]
      # }else{
      #   res_pval[m,n] <- 1
      # }
    }
    
    cat("Epistasis scan invloving Marker",m,"completed\n")
  }
  
  # write.table(res_eff,paste0("MapQTL_MPH_effect_ad_",trait,"_forad.txt"),quote=FALSE)
  # write.table(res_pval,paste0("MapQTL_MPH_pval_ad_",trait,"_forad.txt"),quote=FALSE)
}
bench::mark(
  rcpp_thread4 = ca_epi_pval_eff(epi_pval@address,epi_eff@address,epi_data@address,epi_index@address,combos@address,4),
  rcpp_thread1 = ca_epi_pval_eff(epi_pval@address,epi_eff@address,epi_data@address,epi_index@address,combos@address,1),
  for_ad = for_ad(),
  check = FALSE,
  min_time=Inf,
  iterations=10,
  memory = FALSE
)


# 将big.matrix写入到文本文件中 ####
## 打开一个文本文件
con <- file("epi_pval_thread4.txt", "w")

# 写入列名
cat(paste(total_ma_names, collapse = " "), file = con, sep = "\n")

# 逐行写入
for (i in 1:nrow(epi_pval)) {
  row_data <- as.vector(epi_pval[i, ])
  cat(paste(total_ma_names[i],paste(row_data, collapse = " "),collapse = " "), file = con, sep = "\n")
}

## 关闭文件
close(con)

## 打开一个文本文件
con <- file("epi_eff_thread4.txt", "w")

# 写入列名
cat(paste(total_ma_names, collapse = " "), file = con, sep = "\n")

# 逐行写入
for (i in 1:nrow(epi_eff)) {
  row_data <- as.vector(epi_eff[i, ])
  cat(paste(total_ma_names[i],paste(row_data, collapse = " "),collapse = " "), file = con, sep = "\n")
}

## 关闭文件
close(con)

