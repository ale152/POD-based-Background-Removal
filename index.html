<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
  "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
<meta name="generator" content="jemdoc, see http://jemdoc.jaboc.net/" />
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
<link rel="stylesheet" href="jemdoc.css" type="text/css" />
<link rel="stylesheet" href="custom.css" type="text/css" />
</head>
<body>
<table summary="Table for page layout." id="tlayout">
<tr valign="top">
<td id="layout-content">
<div id="toptitle">
<h1>POD-based background removal for Particle Image Velocimetry</h1>
</div>
<table class="imgtable"><tr><td>
<img src="./figures/header.png" alt="POD background removal" width="500px" />&nbsp;</td>
<td align="left"><p><b><a href="mailto:mendez@vki.ac.be">M.A. Mendez</a><sup>a</sup>, M. Raiola<sup>b</sup>, A. Masullo<sup>c</sup>, S. Discetti<sup>b</sup>, A. Ianiro<sup>b</sup>, R. Theunissen<sup>c</sup>, J.-M.Buchlin<sup>a</sup></b></p>
<p><sup>a</sup> <i>von Karman Institute for Fluid Dynamics</i>, Waterloosesteenweg 72, Sint-Genesius-Rode, Belgium</p>
<p><sup>b</sup> Aerospace Engineering Group, <i>Universidad Carlos III de Madrid</i>, Av. de la Universidad 30, Leganés, Spain</p>
<p><sup>c</sup> Department of Aerospace Engineering, <i>University of Bristol</i>, University Walk, BS81TR, Bristol, UK</p>
</td></tr></table>
<h2>Objective</h2>
<p>This website provides an <a href="download.MD">implementation</a> of the POD-based background removal algorithm described in the paper <a href="paper.MD"><i>POD-based background removal for Particle Image Velocimetry</i></a>. The method consists in approximating the background noise source and the PIV particle pattern with reduced order models (ROM) constructed from different portions of the video sequence’s POD spectra. Particles images and background noise are therefore distinguished according to a novel criterion: the higher degree of correlation of the background noise compared to the one of the particle pattern. Correlated background noise can be well approximated by a few of the first POD modes of the video, while the PIV particle pattern is equally distributed along the entire POD spectra. The proposed method is therefore a POD filter, which automatically identifies &ndash;and remove&ndash; the minimal number of modes representing the background noise.</p>
<h2>POD Decomposition of PIV image recordings</h2>
<p>Let a PIV image sequence be composed of <img class="eq" src="eqs/1403124344-130.png" alt="n_t" style="vertical-align: -4px" /> grayscale images <img class="eq" src="eqs/1121153395-130.png" alt="Im(i,j)in mathbb{R}^{n_xtimes n_y}" style="vertical-align: -5px" /> having a resolution of <img class="eq" src="eqs/199924934-130.png" alt="n_p=n_x n_y" style="vertical-align: -6px" /> pixels. By reshaping each image into a column vector <img class="eq" src="eqs/593408283-130.png" alt="s_iin mathbb{R}^{n_ptimes 1}" style="vertical-align: -4px" />, it is possible to assemble the sequence into a snapshots matrix <img class="eq" src="eqs/1620868007-130.png" alt="X" style="vertical-align: -0px" />:</p>

<div class="eqwl"><img class="eqwl" src="eqs/1991120734-130.png" alt="(1)quad X={ s_1, s_2, dots s_{n_t}} in  mathbb{R}^{n_ptimes n_t}" />
<br /></div><p>The scope of low dimensional modeling of matrix <img class="eq" src="eqs/1620868007-130.png" alt="X" style="vertical-align: -0px" /> is to find the approximation <img class="eq" src="eqs/1877670126-130.png" alt="tilde X in mathbb{R}^{n_ptimes n_t}" style="vertical-align: -1px" /> of rank <img class="eq" src="eqs/653047484-130.png" alt="r&lt;n_t" style="vertical-align: -4px" /> minimizing the <img class="eq" src="eqs/1129993792-130.png" alt="L_2" style="vertical-align: -3px" /> norm (<img class="eq" src="eqs/1935735335-130.png" alt="||cdot||" style="vertical-align: -5px" />) of the error matrix <img class="eq" src="eqs/545639425-130.png" alt="E_r" style="vertical-align: -4px" />:</p>

<div class="eqwl"><img class="eqwl" src="eqs/19233633-130.png" alt=" (2)quad min(E_r)=min biggl (|| X-tilde X||_2 biggl ) ,. " />
<br /></div><p>The solution to this minimization problem, given by the Eckart-Young theorem, is the <img class="eq" src="eqs/1707142003-130.png" alt="r" style="vertical-align: -1px" /> truncated singular value decomposition of the original matrix:</p>

<div class="eqwl"><img class="eqwl" src="eqs/2059533781-130.png" alt=" (3)quad tilde X=Phi_r ,  Sigma_r , { Psi^T_r} rightarrow tilde s_i=sum_{k=1}^{r}phi_k  sigma_k  psi_k^{i} , , " />
<br /></div><p>with <img class="eq" src="eqs/241601158-130.png" alt="Phi_r=[phi_1,dotsphi_{r}] in mathbb{R}^{n_ptimes r}" style="vertical-align: -5px" /> the orthonormal basis for the columns of <img class="eq" src="eqs/1620868007-130.png" alt="X" style="vertical-align: -0px" />, <img class="eq" src="eqs/2000686822-130.png" alt="Psi_r=[psi_1,dotspsi_{r}]in mathbb{R}^{n_ttimes r}" style="vertical-align: -5px" /> the orthonormal basis for the rows of <img class="eq" src="eqs/1620868007-130.png" alt="X" style="vertical-align: -0px" />, and <img class="eq" src="eqs/355591247-130.png" alt="Sigma_r=diag(sigma_1dotssigma_r)in mathbb{R}^{rtimes r}" style="vertical-align: -5px" /> the diagonal matrix containing the norm of each contribution.</p>
<p>In low rank modeling for video analysis, the images forming the spatial basis <img class="eq" src="eqs/1886821793-130.png" alt="phi" style="vertical-align: -4px" /> are referred to as <i>eigenbackgrounds</i>. By definition, the <img class="eq" src="eqs/990404925-130.png" alt="phi_k" style="vertical-align: -4px" /> are eigenvectors of the outer product matrix <img class="eq" src="eqs/1333152113-130.png" alt="C=X X^T in mathbb{R}^{n_ptimes n_p}" style="vertical-align: -1px" /> and the <img class="eq" src="eqs/992495332-130.png" alt="psi_k" style="vertical-align: -4px" /> are eigenvectors of the inner product matrix <img class="eq" src="eqs/1490533056-130.png" alt="K=X^T Xin mathbb{R}^{n_ttimes n_t}" style="vertical-align: -1px" />, while the singular values <img class="eq" src="eqs/968991781-130.png" alt="sigma_k" style="vertical-align: -4px" /> are the square root of the corresponding eigenvalues <img class="eq" src="eqs/1807936694-130.png" alt="lambda_k" style="vertical-align: -4px" />;</p>

<div class="eqwl"><img class="eqwl" src="eqs/1706065678-130.png" alt=" (4a)quad C=X,X^T=bigl( Phi Sigma  Psi^Tbigr)bigl( Psi Sigma  Phi^T bigr)= Phi{Lambda} Phi^T " />
<br /></div>
<div class="eqwl"><img class="eqwl" src="eqs/818746587-130.png" alt=" (4b)quad K=X^T ,X=bigl(  Psi  Sigma  Phi^T bigr) bigl(  Phi  Sigma  Psi^Tbigr)=  Psi {Lambda}  Psi^T  " />
<br /></div><p>The solutions to the eigenvalue problems expressed in eq.s (4a) and (4b) are the discrete versions of the Fredholm Equations, leading, respectively, to the definitions of standard POD (preferable when <img class="eq" src="eqs/1795410640-130.png" alt="n_pll n_t" style="vertical-align: -6px" />) or the Snapshot POD (preferable when <img class="eq" src="eqs/75989792-130.png" alt="n_tll n_p" style="vertical-align: -6px" />). It should be noted that both definitions are common in the analysis of turbulent flows where instead of intensities, element entries of column vectors <img class="eq" src="eqs/585590088-130.png" alt="s_i" style="vertical-align: -4px" /> refer to velocities. </p>
<p>Observing that <img class="eq" src="eqs/322359409-130.png" alt="{X} {Psi}_r={ Phi}_r  {Sigma}_r " style="vertical-align: -4px" />, eq. (3) can be also written as:</p>

<div class="eqwl"><img class="eqwl" src="eqs/2093604075-130.png" alt=" (5)quad {tilde X}= Phi_{r} ,  Phi_{r}^T ,  {X} rightarrow tilde s_i=sum_{k=1}^{r}bigl( phi_k^T s_ibigr) phi_k , . " />
<br /></div><p>This form of the equation, with no emphasis on the temporal evolution of the modes, describes the decomposition as the projection of the data set (of rank <img class="eq" src="eqs/1403124344-130.png" alt="n_t" style="vertical-align: -4px" />) into a lower dimensional space (of rank <img class="eq" src="eqs/653047484-130.png" alt="r&lt;n_t" style="vertical-align: -4px" />) spanned by the orthonormal basis images <img class="eq" src="eqs/1399473050-130.png" alt=" Phi_r=[phi_1,dotsphi_{r}]" style="vertical-align: -5px" />. This formulation is common in Principal Component Analysis where it is introduced in the framework of variance maximization or minimal error of the approximation matrix <img class="eq" src="eqs/903591014-130.png" alt="tilde X" style="vertical-align: -0px" />. </p>
<p>The POD image preprocessing proposed in this work considers a PIV sequence as the sum of an ideal sequence <img class="eq" src="eqs/1860092490-130.png" alt="X_p" style="vertical-align: -6px" /> (i.e. bright particle images superimposed onto a black background) and a background noise sequence <img class="eq" src="eqs/1860092508-130.png" alt="X_b" style="vertical-align: -4px" />, each having their own singular value decomposition:</p>

<div class="eqwl"><img class="eqwl" src="eqs/1837780095-130.png" alt=" (6)quad X={Phi} {Sigma} {Psi}^T=X_p+X_b={Phi}_p {Sigma}_p {Psi}_p^T +{Phi}_b {Sigma}_b {Psi}_b^T ,,, " />
<br /></div><p>with <img class="eq" src="eqs/1528607977-130.png" alt="Phi_p=[phi_{p1},dots, phi_{p n_t}]" style="vertical-align: -6px" /> and <img class="eq" src="eqs/1420922269-130.png" alt="Phi_b=[phi_{b1},dots, phi_{b n_t}]" style="vertical-align: -6px" /> the eigenbackgrounds of <img class="eq" src="eqs/1673274964-130.png" alt="{X_p}" style="vertical-align: -6px" /> and <img class="eq" src="eqs/1687274926-130.png" alt="{X_b}" style="vertical-align: -4px" />. Typical background noise in PIV has a high degree of spatial and temporal correlation, resulting in multiple rows and columns of <img class="eq" src="eqs/1860092508-130.png" alt="X_b" style="vertical-align: -4px" /> being similar to each others. Therefore, the matrix <img class="eq" src="eqs/1860092508-130.png" alt="X_b" style="vertical-align: -4px" /> is close to be rank deficient and can be well captured by few (<img class="eq" src="eqs/345200389-130.png" alt="rll n_t" style="vertical-align: -4px" />) of its modes, such that</p>

<div class="eqwl"><img class="eqwl" src="eqs/1607574486-130.png" alt=" (7)quad X_bapprox tilde{X}_b=sum_{k=1}^{r}phi_{bk}sigma_{bk}psi^T_{bk} , | , ,sigma_{bk}approx 0 , forall k&gt;r ll n_t , ,, " />
<br /></div><p>with <img class="eq" src="eqs/1808662104-130.png" alt="rank(tilde{X}_b)={rll n_t}" style="vertical-align: -5px" />. It is worth observing that, besides allowing for the background noise to be time dependent &ndash;contrary to simple levelization approaches&ndash; the proposed method also allows for the video sequence to be temporally unresolved &ndash;contrary to time filtering approaches&ndash;.</p>
<p>A temporally unresolved sequence can in fact be constructed from column permutation of a time-resolved sequence, and the SVD decomposition in eq. (3) &ndash;thus the approximation in eq. (7)&ndash; is invariant under column permutation of the decomposed matrix.</p>
<p>From eq.s (6-7), the proposed method consist in constructing an approximation of <img class="eq" src="eqs/1860092490-130.png" alt="X_p" style="vertical-align: -6px" /> and <img class="eq" src="eqs/1860092508-130.png" alt="X_b" style="vertical-align: -4px" /> using the POD modes of <img class="eq" src="eqs/1620868007-130.png" alt="X" style="vertical-align: -0px" />. The method is based upon two assumptions, which are justified in the reference paper:</p>
<dl>
<dt><b>Assumption 1</b></dt>
<dd><p>For <img class="eq" src="eqs/1227554142-130.png" alt="{k&gt;r}" style="vertical-align: -1px" />, the contribution of the ideal PIV sequence <img class="eq" src="eqs/1860092490-130.png" alt="X_p" style="vertical-align: -6px" /> is equally distributed, such that <img class="eq" src="eqs/1947592362-130.png" alt="sigma_{pk}approx sigma_{pk+1} , forall kin [r, n_t]" style="vertical-align: -6px" />.</p></dd>
<dt><b>Assumption 2</b></dt>
<dd><p>For <img class="eq" src="eqs/1227554142-130.png" alt="{k&gt;r}" style="vertical-align: -1px" />, the decomposition of the video <img class="eq" src="eqs/1620868007-130.png" alt="X" style="vertical-align: -0px" /> is aligned with that of the ideal PIV sequence <img class="eq" src="eqs/1860092490-130.png" alt="X_p" style="vertical-align: -6px" />, such that <img class="eq" src="eqs/301571065-130.png" alt="sigma_{k}approx sigma_{pk} , forall kin [r, n_t]" style="vertical-align: -6px" />.</p></dd>
</dl>
<h2>Proposed Algorithm</h2>
<p>Since <img class="eq" src="eqs/345200389-130.png" alt="rll n_t" style="vertical-align: -4px" /> and <img class="eq" src="eqs/818746230-130.png" alt="sigma_{pk}approx sigma_{pk+1}" style="vertical-align: -6px" /> (Assumption 1), it is possible to approximate the ideal PIV video sequence <img class="eq" src="eqs/1860092490-130.png" alt="X_p" style="vertical-align: -6px" /> underlying the video sequence <img class="eq" src="eqs/1620868007-130.png" alt="X" style="vertical-align: -0px" />  (eq. (6)) filtering out its first <img class="eq" src="eqs/1707142003-130.png" alt="r" style="vertical-align: -1px" /> POD modes:</p>

<div class="eqwl"><img class="eqwl" src="eqs/1111498472-130.png" alt=" X_p= sum_{k=1}^{n_t} phi_{pk} sigma_{pk} psi_{pk}^Tapproxtilde{X}_p=sum_{k=r+1}^{n_t} phi_{pk} sigma_{pk} psi_{pk}^T ,, . " />
<br /></div><p>Moreover, since <img class="eq" src="eqs/301571065-130.png" alt="sigma_{k}approx sigma_{pk} , forall kin [r, n_t]" style="vertical-align: -6px" /> (Assumption 2), it is reasonable to expect the decomposition of <img class="eq" src="eqs/1620868007-130.png" alt="X" style="vertical-align: -0px" /> to be aligned with that of <img class="eq" src="eqs/1860092490-130.png" alt="X_p" style="vertical-align: -6px" /> for <img class="eq" src="eqs/1857396-130.png" alt="k&gt;r" style="vertical-align: -1px" />. Therefore, using eq. (5} yields:</p>

<div class="eqwl"><img class="eqwl" src="eqs/665245069-130.png" alt=" tilde{X}_papprox tilde{X}=sum_{k=r+1}^{n_t} phi_{k} sigma_{k} psi_{k}^T =tilde {Phi} tilde {Phi}^T X , " />
<br /></div><p>where <img class="eq" src="eqs/7588202-130.png" alt="tilde {Phi}=[phi_{r+1},dots phi_{n_t}]" style="vertical-align: -6px" /> is the basis for the reduced order model of <img class="eq" src="eqs/1860092490-130.png" alt="X_p" style="vertical-align: -6px" />. In addition to the equality of singular values,  the modes approximating the PIV pattern should have a temporal <img class="eq" src="eqs/992495332-130.png" alt="psi_k" style="vertical-align: -4px" />, for <img class="eq" src="eqs/1227554142-130.png" alt="{k&gt;r}" style="vertical-align: -1px" />, orthonormal to <img class="eq" src="eqs/2078265819-130.png" alt="psi_{p1}=underline{1}" style="vertical-align: -6px" />, i.e. <img class="eq" src="eqs/2114345496-130.png" alt="langle psi_{k},underline{1} rangle=sum_{j=1}^{n_t} psi^j_{k}=0" style="vertical-align: -9px" />, as discussed in the paper. These two constraints are used to identify the <img class="eq" src="eqs/273399736-130.png" alt="[r+1,n_t]" style="vertical-align: -5px" /> POD modes approximating the PIV pattern, to be retained in the preprocessing. Then, the method consists in constructing the reduced basis onto which project the set of images. If significant light variations appear between two frames <img class="eq" src="eqs/468864544-130.png" alt="a" style="vertical-align: -1px" /> and <img class="eq" src="eqs/340864157-130.png" alt="b" style="vertical-align: -1px" />, the method should be applied independently on the two series of camera exposures. The pseudo-code of the proposed method is summarized in the following algorithm, where the tolerances in line 7 are set as <img class="eq" src="eqs/1533984249-130.png" alt="varepsilon_1=0.01sigma_{pk}=0.01sqrt{n_p}sigma_{sp}" style="vertical-align: -8px" /> and <img class="eq" src="eqs/1847499804-130.png" alt="varepsilon_2=0.01" style="vertical-align: -3px" />:</p>
<ol>
<li><p><i>Reshape Images <img class="eq" src="eqs/345889086-130.png" alt="Imin mathbb{R}^{n_xtimes n_y}" style="vertical-align: -1px" /> in <img class="eq" src="eqs/593408283-130.png" alt="s_iin mathbb{R}^{n_ptimes 1}" style="vertical-align: -4px" />}$</i></p>
</li>
<li><p><i>Assemble Matrix <img class="eq" src="eqs/621385232-130.png" alt="Xin mathbb{R}^{n_ptimes n_t}" style="vertical-align: -1px" />}$</i></p>
</li>
<li><p><i>Compute <img class="eq" src="eqs/1499718005-130.png" alt="K=X^T X" style="vertical-align: -0px" />}$</i></p>
</li>
<li><p><i>Diagonalize <img class="eq" src="eqs/566379045-130.png" alt="K=Psi , Sigma^2 , Psi^T" style="vertical-align: -0px" /> }$</i></p>
</li>
<li><p><i>Compute <img class="eq" src="eqs/330089084-130.png" alt="Phi=X , Psi , Sigma^{-1}" style="vertical-align: -0px" />}$</i></p>
</li>
<li><p><i>Find <img class="eq" src="eqs/702481134-130.png" alt="r:" style="vertical-align: -1px" /> <img class="eq" src="eqs/437777783-130.png" alt="sigma_{k+1}-sigma_k&lt;varepsilon_1 , & , langle underline{1}, psi_{pk}rangle &lt; varepsilon_2 ,, forall k&gt;r" style="vertical-align: -6px" />}$label{line}</i></p>
</li>
<li><p><i>Construct <img class="eq" src="eqs/338470197-130.png" alt="tilde{Phi}=[phi_{r+1},dots phi_{n_t}]" style="vertical-align: -6px" />}$</i></p>
</li>
<li><p><i>Compute <img class="eq" src="eqs/1446602181-130.png" alt="tilde{X}=tilde{Phi}tilde{Phi}^T X" style="vertical-align: -0px" /> with <img class="eq" src="eqs/28656246-130.png" alt="tilde{X}=[tilde{x_1},dots tilde{x_{n_t}}]" style="vertical-align: -6px" />}$</i></p>
</li>
<li><p><i>Reshape <img class="eq" src="eqs/1750038361-130.png" alt="tilde{s}_iin mathbb{R}^{n_ptimes 1}" style="vertical-align: -4px" /> back to <img class="eq" src="eqs/426174528-130.png" alt="tilde{Im}in mathbb{R}^{n_xtimes n_y}" style="vertical-align: -1px" />}$</i></p>
</li>
</ol>
<p><br /></p>
<table class="imgtable"><tr><td>
<img src="./figures/psi_sigma.png" alt="Analysis of statistical convergence on synthetic PIV images" />&nbsp;</td>
<td align="left"></td></tr></table>
<p><i>Analysis of statistical convergence on synthetic PIV images with source density <img class="eq" src="eqs/1570893117-130.png" alt="N_S=0.02" style="vertical-align: -4px" /> and <img class="eq" src="eqs/1137395683-130.png" alt="N_S=0.9" style="vertical-align: -4px" />.</i></p>
<div id="footer">
<div id="footer-text">
Page generated 2017-09-19 19:12:11 GMT Daylight Time, by <a href="http://jemdoc.jaboc.net/">jemdoc</a>.
</div>
</div>
</td>
</tr>
</table>
</body>
</html>
