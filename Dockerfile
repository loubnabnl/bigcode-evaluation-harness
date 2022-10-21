FROM pytorch/pytorch:1.12.1-cuda11.3-cudnn8-runtime

RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash
RUN apt-get update && apt-get install -y git-lfs

RUN ulimit -n 50000


RUN pip install transformers accelerate datasets==2.6.1 evaluate pyext==0.7 mosestokenizer==1.0.0 huggingface_hub

WORKDIR /
RUN git clone https://huggingface.co/datasets/loubnabnl/code-generations-bigcode
WORKDIR /code-generations-bigcode
RUN git lfs pull
RUN mkdir /beh
RUN cp /code-generations-bigcode/codeparrotdedup-08/generations.json /beh/

COPY ./ /beh

RUN chmod 777 -R /beh
ENV PYTHONHASHSEED=0
ENV PYTHONPATH="/beh:${PYTHONPATH}"
ENV XDG_CACHE_HOME=/repo_workdir/hgf_root


WORKDIR /beh

