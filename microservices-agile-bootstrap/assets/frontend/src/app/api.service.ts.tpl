import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

export interface Item {
  id: string;
  name: string;
  createdAt: string;
}

/** Acces generique aux ressources exposees par la passerelle (/api/<ressource>). */
@Injectable({ providedIn: 'root' })
export class ApiService {
  constructor(private readonly http: HttpClient) {}

  list(resource: string): Observable<Item[]> {
    return this.http.get<Item[]>(`/api/${resource}`);
  }

  create(resource: string, name: string): Observable<Item> {
    return this.http.post<Item>(`/api/${resource}`, { name });
  }
}
